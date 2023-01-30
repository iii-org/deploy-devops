import argparse
from typing import Any, Dict, List

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


def create_user(
    access_token: str,
    *,
    username: str = None,
    email: str = None,
    firstname: str = None,
    lastname: str = None,
    password: str = None,
    groups: List[str] = None,
):
    url: str = f"{BASE_RESTFUL}/IIIdevops/users"

    headers: dict[str, str] = {
        "content-type": "application/json",
        "Authorization": f"Bearer {access_token}",
    }

    params: Dict[str, Any] = {
        "enabled": True,
    }

    if username:
        params["username"] = username

    if email:
        params["email"] = email
        params["emailVerified"] = True

    if firstname:
        params["firstName"] = firstname

    if lastname:
        params["lastName"] = lastname

    if password:
        params["credentials"] = [
            {"type": "password", "value": password, "temporary": False}
        ]

    if groups:
        params["groups"] = groups

    r = requests.post(url, json=params, headers=headers, verify=False)

    if r.ok:
        print(f"[INFO] {params.get('username')} created successfully")

    elif r.status_code == 409:
        print(f"[INFO] {params.get('username')} already exists")

    else:
        raise ValueError(f"Create client failed, {r.text}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create user in keycloak")
    parser.add_argument("kc_account", type=str, help="admin account of keycloak")
    parser.add_argument("kc_password", type=str, help="admin password of keycloak")
    parser.add_argument("kc_base", type=str, help="keycloak base url")
    parser.add_argument("--username", type=str, help="New user name", required=True)
    parser.add_argument("--email", type=str, help="New user email")
    parser.add_argument("--firstname", type=str, help="New user firstname")
    parser.add_argument("--lastname", type=str, help="New user lastname")
    parser.add_argument("--password", type=str, help="New user password")
    parser.add_argument(
        "--groups", type=str, nargs="+", help="New user groups, if exist"
    )

    args = parser.parse_args()

    KEYCLOAK_URL: str = args.kc_base
    BASE_RESTFUL: str = f"{KEYCLOAK_URL}/admin/realms"

    token: str = get_token(args.kc_account, args.kc_password)

    create_user(
        token,
        username=args.username,
        email=args.email,
        firstname=args.firstname,
        lastname=args.lastname,
        password=args.password,
        groups=args.groups,
    )
