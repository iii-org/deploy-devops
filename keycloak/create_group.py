import argparse
from typing import Any, Dict

import requests
import urllib3

urllib3.disable_warnings()


def get_token(acc: str, password: str):
    url = f"{KEYCLOAK_URL}/realms/master/protocol/openid-connect/token"

    params: dict[str, str] = {
        "client_id": "admin-cli",
        "grant_type": "password",
        "username": acc,
        "password": password,
    }
    r = requests.post(url, params, verify=False)

    if r.ok:
        return r.json().get("access_token")

    raise ValueError("[ERROR] Get token failed, please check your account and password")


def create_group(
    access_token: str,
    *,
    name: str = None,
):
    url: str = f"{BASE_RESTFUL}/IIIdevops/groups"

    headers: dict[str, str] = {
        "content-type": "application/json",
        "Authorization": f"Bearer {access_token}",
    }

    params: Dict[str, Any] = {
        "name": name,
    }

    r = requests.post(url, json=params, headers=headers, verify=False)

    if r.ok:
        print(f"[INFO] Create group {name} successfully")

    elif r.status_code == 409:
        print(f"[INFO] {params.get('name')} already exists")

    else:
        raise ValueError(f"Create group failed, {r.text}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create user in keycloak")
    parser.add_argument("kc_account", type=str, help="admin account of keycloak")
    parser.add_argument("kc_password", type=str, help="admin password of keycloak")
    parser.add_argument("kc_base", type=str, help="keycloak base url")
    parser.add_argument("--name", type=str, help="New group name", required=True)

    args = parser.parse_args()

    KEYCLOAK_URL: str = args.kc_base
    BASE_RESTFUL: str = f"{KEYCLOAK_URL}/admin/realms"

    token: str = get_token(args.kc_account, args.kc_password)

    create_group(
        token,
        name=args.name,
    )
