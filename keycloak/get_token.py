import argparse

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


def get_client(access_token: str, option: str):
    url: str = f"{BASE_RESTFUL}/IIIdevops/clients"

    headers: dict[str, str] = {
        "content-type": "application/json",
        "Authorization": f"Bearer {access_token}",
    }

    r = requests.get(url, headers=headers, verify=False)

    if r.ok:
        for _ in r.json():
            if option == _.get("clientId"):
                return _

        return None

    else:
        raise ValueError(f"[ERROR] Get client failed, {r.text}")


def get_client_secret(access_token: str, option: str):
    client = get_client(access_token, option)

    if client:
        return client.get("secret")

    raise ValueError(f"[ERROR] Get client secret failed, {option} not found")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create client in keycloak")
    parser.add_argument("account", type=str, help="admin account of keycloak")
    parser.add_argument("password", type=str, help="admin password of keycloak")
    parser.add_argument("keycloak_base", type=str, help="keycloak base url")
    parser.add_argument("option", type=str, help="what client secret to get")

    args = parser.parse_args()

    KEYCLOAK_URL: str = args.keycloak_base
    BASE_RESTFUL: str = f"{KEYCLOAK_URL}/admin/realms"

    token: str = get_token(args.account, args.password)
    print(get_client_secret(token, args.option))
