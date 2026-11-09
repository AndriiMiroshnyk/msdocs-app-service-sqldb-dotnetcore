#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 4 ] || [ "$#" -gt 5 ]; then
  echo "Usage: $0 RESOURCE_GROUP APP SLOT LOCAL_BUNDLE [TIMEOUT_SECONDS]" >&2
  exit 2
fi
resource_group=$1
web_app=$2
slot=$3
bundle=$4
migration_timeout=${5:-600}
if ! [[ "$migration_timeout" =~ ^[1-9][0-9]*$ ]] || [ "$migration_timeout" -gt 3600 ]; then
  echo "TIMEOUT_SECONDS must be between 1 and 3600." >&2
  exit 2
fi
if [ ! -s "$bundle" ]; then
  echo "Migration bundle is missing or empty: $bundle" >&2
  exit 1
fi
bundle_hash=$(sha256sum "$bundle" | cut -d ' ' -f 1)

target=(--resource-group "${resource_group}" --name "${web_app}" --slot "${slot}")
# Requires Azure CLI >= 2.90.
az webapp exec --help > /dev/null
instance=$(az webapp list-instances "${target[@]}" --query '[0].name' --output tsv)
scm_hostname=$(az webapp show "${target[@]}" \
  --query "enabledHostNames[?contains(@, '.scm.')]|[0]" --output tsv)
test -n "$instance" && test -n "$scm_hostname"

run_id=$(cat /proc/sys/kernel/random/uuid)
remote_log="/home/LogFiles/ef-migration-$run_id.log"
remote_exit="/home/LogFiles/ef-migration-$run_id.exit"
remote_command=$(cat <<EOF
mkdir -p /home/LogFiles || exit 1
(
  set -eu
  cd /home/site/wwwroot
  echo "$bundle_hash  efbundle" | sha256sum -c -
  chmod +x ./efbundle
  timeout --kill-after=10s ${migration_timeout}s ./efbundle -- --environment Production
) > "$remote_log" 2>&1
result=\$?
printf '%s\n' "\$result" > "$remote_exit.tmp"
mv "$remote_exit.tmp" "$remote_exit"
EOF
)
az webapp exec "${target[@]}" --instance "$instance" --mode execute \
  --target app --shell /bin/sh --shell-command "$remote_command" --output none

# Submission only confirms acceptance. Poll this run's actual exit code.
token=$(az account get-access-token --resource https://appservice.azure.com \
  --query accessToken --output tsv)
status_file=$(mktemp)
trap 'rm -f "$status_file"' EXIT
deadline=$((SECONDS + migration_timeout + 30))
completed=false
while [ "$SECONDS" -lt "$deadline" ]; do
  http_status=$(curl --silent --show-error --connect-timeout 10 --max-time 20 \
    --header "Authorization: Bearer $token" \
    --header "Cookie: ARRAffinity=$instance" --header 'Cache-Control: no-cache' \
    --output "$status_file" --write-out '%{http_code}' \
    "https://$scm_hostname/api/vfs/LogFiles/ef-migration-$run_id.exit") || http_status=000
  case "$http_status" in
    200)
      result=$(tr -d '\r\n' < "$status_file")
      if [ "$result" != 0 ]; then
        echo "Migrations failed (status: $result). Inspect $remote_log in staging."
        exit 1
      fi
      completed=true
      break
      ;;
    000|404|409|429|502|503|504) sleep 5 ;;
    *) echo "Cannot read migration status: HTTP $http_status. Check SCM permissions."; exit 1 ;;
  esac
done
if [ "$completed" != true ]; then
  echo "Migration completion unconfirmed. Inspect $remote_log and $remote_exit before retrying."
  exit 1
fi
echo "Database migrations completed successfully."

staging_hostname=$(az webapp show \
  --resource-group "${resource_group}" \
  --name "${web_app}" \
  --slot "${slot}" \
  --query defaultHostName --output tsv)
test -n "$staging_hostname"
echo "##vso[task.setvariable variable=stagingUrl]https://$staging_hostname/"
