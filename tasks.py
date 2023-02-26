import json
import os
import subprocess
from pathlib import Path

from invoke import task

PERSISTENT_WORKSPACES = ["dev", "prod"]
ROOT_ZONE = "vajeh.co.uk"

tf_dir = os.getenv("TF_DIR", os.getcwd())


def load_project_conf():
    conf_dir = tf_dir

    with open(f"{conf_dir}/project.env.json", 'r') as public_conf_file:
        public_conf = json.load(public_conf_file)

    def get_param(k, default):
        return os.getenv(k, public_conf.get(k, default))

    conf = public_conf | {
        "PROJECT": get_param("PROJECT", Path(os.getcwd()).stem),
        "ENVIRONMENT": get_param("ENVIRONMENT", "dev"),
        "WORKSPACE": get_param("WORKSPACE", "dev"),

        "AWS_ACCESS_KEY_ID": os.getenv("AWS_ACCESS_KEY_ID", ""),
        "AWS_SECRET_ACCESS_KEY": os.getenv("AWS_SECRET_ACCESS_KEY", ""),
    }
    try:
        with open(f"{conf_dir}/project.private.env.json", 'r') as private_conf_file:
            private_conf = json.load(private_conf_file)
            return conf | private_conf

    except FileNotFoundError:
        print(
            "Private environment file not found. "
            "Using only default values and environment variables for private settings.")
        return conf


config = load_project_conf()
# config will overwrite environment variables
os.environ.update(config)


def print_settings():
    # DO NOT print the whole config. There are secrets in there
    print("Settings:")
    print(
        f"PROJECT: {config['PROJECT']}\nENVIRONMENT: {config['ENVIRONMENT']}\n"
        f"WORKSPACE: {config['WORKSPACE']}\nTF_DIR: {tf_dir}\n")


aws_account = "ptl" if config['ENVIRONMENT'] != "prod" else "prod"
tf_state_bucket = f"{config['PROJECT']}-{aws_account}-terraform-state"


def parse_workspace_list(output):
    workspaces = []
    current_ws = None
    for ws in output.split("\n"):
        _ws = ws.strip()
        if _ws.startswith("*"):
            current_ws = _ws.lstrip("*").strip()
            workspaces.append(current_ws)
        elif _ws != "":
            workspaces.append(_ws)
    return workspaces, current_ws


def get_terraform_workspaces() -> (list[str], str):
    s = subprocess.check_output(["terraform", f"-chdir={tf_dir}", "workspace", "list"])
    return parse_workspace_list(s.decode("utf-8"))


def switch_workspace(ws):
    subprocess.run(["terraform", f"-chdir={tf_dir}", "workspace", "select", ws])


def create_workspace(ws):
    subprocess.run(["terraform", f"-chdir={tf_dir}", "workspace", "new", ws])


def delete_workspace(ws):
    (_, current) = get_terraform_workspaces()
    if ws == "default" or current == "default":
        return
    switch_workspace("default")
    subprocess.run(["terraform", f"-chdir={tf_dir}", "workspace", "delete", ws])


def get_tf_vars():
    (_, ws) = get_terraform_workspaces()
    workspace_tag = ws
    if ws not in PERSISTENT_WORKSPACES and not ws.startswith("pr-"):
        workspace_tag = f"user-{ws}"

    account_zone = f"{aws_account}.{ROOT_ZONE}"

    all_vars = {"project": config["PROJECT"], "workspace_tag": workspace_tag, "account_zone": account_zone}

    tf_vars = ""
    for k, v in all_vars.items():
        tf_vars += f"-var=\"{k}={v}\" "

    return tf_vars


@task(help={"ws": "Terraform workspace. Set default via WORKSPACE in env var or .env file"})
def workspace(c, ws=config["WORKSPACE"]):
    (wss, current_ws) = get_terraform_workspaces()
    if ws not in wss:
        create_workspace(ws)
    elif ws != current_ws:
        switch_workspace(ws)


@task()
def init(c):
    c.run(f"terraform -chdir={tf_dir} init -backend-config=\"bucket={tf_state_bucket}\"", in_stream=False)
    print("DO NOT FORGET to run `provider-lock` task if, you added new provider/plugin.")


@task(workspace)
def plan(c):
    print_settings()
    tf_vars = get_tf_vars()
    c.run(f"terraform -chdir={tf_dir} plan {tf_vars}", in_stream=False)


@task(workspace)
def apply(c):
    print_settings()
    tf_vars = get_tf_vars()
    c.run(f"terraform -chdir={tf_dir} apply {tf_vars} -auto-approve", in_stream=False)


@task(workspace)
def destroy(c, dryrun=True):
    print_settings()
    (_, ws) = get_terraform_workspaces()
    tf_vars = get_tf_vars()
    if dryrun:
        c.run(f"terraform -chdir={tf_dir} plan {tf_vars} -destroy", in_stream=False)
    else:
        c.run(f"terraform -chdir={tf_dir} destroy {tf_vars} -auto-approve", in_stream=False)
        delete_workspace(ws)


@task(workspace)
def output(c):
    c.run("mkdir -p build", in_stream=False)
    c.run(f"terraform -chdir={tf_dir} output -json", in_stream=False)


@task(workspace)
def lock_providers(c):
    print("This will take a while. Be patient!")
    c.run(f"terraform -chdir={tf_dir} providers lock "
          f"-platform=darwin_arm64 -platform=darwin_amd64 -platform=linux_amd64 -platform=windows_amd64",
          in_stream=False)


@task()
def clean(c):
    c.run(f"rm -rf build")
