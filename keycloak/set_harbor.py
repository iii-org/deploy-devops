import argparse
import base64
from typing import Any

import requests
import urllib3

urllib3.disable_warnings()

TOKEN: str = ""
KEYCLOAK_URL: str = ""
BASE_RESTFUL: str = ""


def set_token(acc: str, password: str):
    url = f"{KEYCLOAK_URL}/realms/master/protocol/openid-connect/token"

    params: dict[str, str] = {
        "client_id": "admin-cli",
        "grant_type": "password",
        "username": acc,
        "password": password,
    }
    r = requests.post(url, params, verify=False)

    if r.ok:
        global TOKEN
        TOKEN = r.json().get("access_token")
        return r.json().get("access_token")

    raise ValueError("[ERROR] Get token failed, please check your account and password")


def get_client(option: str):
    url: str = f"{BASE_RESTFUL}/IIIdevops/clients"

    headers: dict[str, str] = {
        "content-type": "application/json",
        "Authorization": f"Bearer {TOKEN}",
    }

    r = requests.get(url, headers=headers, verify=False)

    if r.ok:
        for _ in r.json():
            if option == _.get("clientId"):
                return _

        return None

    else:
        raise ValueError(f"[ERROR] Get client failed, {r.text}")


def get_harbor_secret():
    client = get_client("harbor")

    if client:
        return client.get("secret")

    raise ValueError(f"[ERROR] Get client secret failed, harbor not found")


def set_harbor(hb_url: str, hb_password: str):
    url: str = f"{hb_url}/api/v2.0/configurations"

    headers: dict[str, str] = {
        "accept": "application/json",
        "authorization": f"Basic {base64.b64encode(bytes(f'admin:{hb_password}'.encode())).decode()}",
        "Content-Type": "application/json",
    }

    params: dict[str, Any] = {
        "auth_mode": "oidc_auth",
        "oidc_name": "keycloak",
        "oidc_endpoint": f"{KEYCLOAK_URL}/realms/IIIdevops",
        "oidc_client_id": "harbor",
        "oidc_client_secret": get_harbor_secret(),
        "oidc_scope": "openid,profile,email,offline_access",
        "oidc_verify_cert": False,
        "oidc_auto_onboard": True,
        "oidc_user_claim": "preferred_username",
    }

    r = requests.put(url, headers=headers, json=params, verify=False)

    if r.ok:
        print(f"[INFO] Setting harbor success")

    else:
        raise ValueError(f"[ERROR] Setting harbor failed, {r.text}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Setting harbor configures")
    parser.add_argument("kc_account", type=str, help="admin account of keycloak")
    parser.add_argument("kc_password", type=str, help="admin password of keycloak")
    parser.add_argument("kc_base", type=str, help="keycloak base url")
    parser.add_argument(
        "--hb_password", type=str, help="Harbor admin password", required=True
    )
    parser.add_argument("--hb_url", type=str, help="Harbor base url", required=True)

    args = parser.parse_args()

    KEYCLOAK_URL: str = args.kc_base
    BASE_RESTFUL: str = f"{KEYCLOAK_URL}/admin/realms"

    set_token(args.kc_account, args.kc_password)
    set_harbor(args.hb_url, args.hb_password)
