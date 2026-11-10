import os
import re
from html.parser import HTMLParser
from uuid import uuid4

from locust import HttpUser, between, task


class TodoPage(HTMLParser):
    def __init__(self, html):
        super().__init__()
        self.forms = []
        self.row = None
        self.form = None
        self.feed(html)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "tr":
            self.row = []
        elif tag == "form":
            self.form = {
                "action": attrs.get("action", ""),
                "token": None,
                "row": self.row,
            }
            self.forms.append(self.form)
        elif tag == "input" and self.form is not None:
            if attrs.get("name") == "__RequestVerificationToken":
                self.form["token"] = attrs.get("value")

    def handle_endtag(self, tag):
        if tag == "tr":
            self.row = None
        elif tag == "form":
            self.form = None

    def handle_data(self, data):
        if self.row is not None:
            self.row.append(data.strip())

    def find_form(self, description=None):
        for form in self.forms:
            if description is None:
                matches = form["action"] == "/Todos/Create"
            else:
                matches = (
                    re.fullmatch(r"/Todos/Delete/\d+", form["action"])
                    and description in (form["row"] or [])
                )
            if matches and form["token"]:
                return form
        return None


class TodoUser(HttpUser):
    host = os.environ.get("TARGET_HOST")
    wait_time = between(1, 3)

    def load_form(self, description=None):
        with self.client.get(
            "/Todos", name="list-todos", timeout=15, catch_response=True
        ) as response:
            if response.status_code != 200:
                response.failure(f"Expected HTTP 200, received {response.status_code}")
                return None
            form = TodoPage(response.text).find_form(description)
            if form is None:
                response.failure("Todo form or antiforgery token missing")
            return form

    @task(4)
    def list_todos(self):
        self.load_form()

    @task(1)
    def create_and_delete_todo(self):
        form = self.load_form()
        if form is None:
            return

        description = f"loadtest-{uuid4().hex}"
        with self.client.post(
            form["action"],
            data={
                "NewTodo.Description": description,
                "__RequestVerificationToken": form["token"],
            },
            name="create-todo",
            allow_redirects=False,
            timeout=15,
            catch_response=True,
        ) as response:
            if response.status_code != 302:
                response.failure(f"Expected HTTP 302, received {response.status_code}")
                return

        form = self.load_form(description)
        if form is None:
            return

        with self.client.post(
            form["action"],
            data={"__RequestVerificationToken": form["token"]},
            name="delete-todo",
            allow_redirects=False,
            timeout=15,
            catch_response=True,
        ) as response:
            if response.status_code != 302:
                response.failure(f"Expected HTTP 302, received {response.status_code}")
