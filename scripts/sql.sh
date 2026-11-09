#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 5 ] || [ "$#" -gt 6 ]; then
  echo "Usage: bash scripts/sql.sh SUBSCRIPTION_ID RESOURCE_GROUP APP SQL_SERVER DATABASE [SLOT]" >&2
  exit 2
fi

subscription_id=$1
rg=$2
app=$3
server=$4
database=$5
slot=${6:-staging}

az account set --subscription "$subscription_id"
az extension add --name serviceconnector-passwordless --upgrade

# Keep the SQL administrator configured by Terraform.
current_user=$(az ad signed-in-user show --query id -o tsv)
sql_admin=$(az sql server ad-admin list \
  -g "$rg" -s "$server" --query '[0].sid' -o tsv)

if [ "$current_user" != "$sql_admin" ]; then
  echo "Sign in as the SQL Entra administrator configured by Terraform." >&2
  exit 1
fi

cleanup() {
  az sql server update -g "$rg" -n "$server" \
    --enable-public-network false -o none
}
trap cleanup EXIT

az sql server update -g "$rg" -n "$server" \
  --enable-public-network true -o none

# Preserve Terraform-managed connection settings for both slots.
common=(
  --resource-group "$rg" --name "$app"
  --target-resource-group "$rg"
  --server "$server" --database "$database"
  --connection defaultConnector
  --client-type dotnet
  --system-identity
  --opt-out configinfo publicnetwork
  --yes --output none
)

az webapp connection create sql "${common[@]}"
az webapp connection create sql "${common[@]}" --slot "$slot"
