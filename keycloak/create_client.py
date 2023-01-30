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


def create_client(access_token: str, params: Dict[str, Any]):
    url: str = f"{BASE_RESTFUL}/IIIdevops/clients"

    headers: dict[str, str] = {
        "content-type": "application/json",
        "Authorization": f"Bearer {access_token}",
    }

    r = requests.post(url, headers=headers, json=params, verify=False)

    if r.ok:
        print(f"[INFO] {params.get('clientId')} client created")

    elif r.status_code == 409:
        print(f"[INFO] Clients {params.get('clientId')} already exists, do nothing")

    else:
        raise ValueError(f"Create client failed, {r.text}")


def create_default_gitlab(access_token: str, base_url: str):
    gitlab_settings = {
        "clientId": "gitlab",
        "name": "IIIdevops GitLab Client",
        "description": "IIIdevops GitLab Client",
        "rootUrl": f"{base_url}/",
        "adminUrl": "",
        "baseUrl": "",
        "surrogateAuthRequired": False,
        "enabled": True,
        "alwaysDisplayInConsole": False,
        "clientAuthenticatorType": "client-secret",
        "redirectUris": [f"{base_url}/users/auth/openid_connect/callback"],
        "webOrigins": [],
        "notBefore": 0,
        "bearerOnly": False,
        "consentRequired": False,
        "standardFlowEnabled": True,
        "implicitFlowEnabled": False,
        "directAccessGrantsEnabled": True,
        "serviceAccountsEnabled": False,
        "publicClient": False,
        "frontchannelLogout": False,
        "protocol": "openid-connect",
        "attributes": {
            "oauth2.device.authorization.grant.enabled": "false",
            "use.jwks.url": "false",
            "backchannel.logout.revoke.offline.tokens": "false",
            "use.refresh.tokens": "true",
            "tls-client-certificate-bound-access-tokens": "false",
            "oidc.ciba.grant.enabled": "false",
            "backchannel.logout.session.required": "false",
            "client_credentials.use_refresh_token": "false",
            "acr.loa.map": "{}",
            "require.pushed.authorization.requests": "false",
            "display.on.consent.screen": "false",
            "token.response.type.bearer.lower-case": "false",
            "request.uris": "",
            "consent.screen.text": "",
            "frontchannel.logout.url": "",
            "backchannel.logout.url": "",
            "login_theme": "",
        },
        "authenticationFlowBindingOverrides": {},
        "fullScopeAllowed": True,
        "nodeReRegistrationTimeout": -1,
        "protocolMappers": [
            {
                "name": "Client ID",
                "protocol": "openid-connect",
                "protocolMapper": "oidc-usersessionmodel-note-mapper",
                "consentRequired": False,
                "config": {
                    "user.session.note": "clientId",
                    "id.token.claim": "true",
                    "access.token.claim": "true",
                    "claim.name": "clientId",
                    "jsonType.label": "String",
                },
            },
            {
                "name": "Client IP Address",
                "protocol": "openid-connect",
                "protocolMapper": "oidc-usersessionmodel-note-mapper",
                "consentRequired": False,
                "config": {
                    "user.session.note": "clientAddress",
                    "id.token.claim": "true",
                    "access.token.claim": "true",
                    "claim.name": "clientAddress",
                    "jsonType.label": "String",
                },
            },
            {
                "name": "Client Host",
                "protocol": "openid-connect",
                "protocolMapper": "oidc-usersessionmodel-note-mapper",
                "consentRequired": False,
                "config": {
                    "user.session.note": "clientHost",
                    "id.token.claim": "true",
                    "access.token.claim": "true",
                    "claim.name": "clientHost",
                    "jsonType.label": "String",
                },
            },
        ],
        "defaultClientScopes": ["web-origins", "acr", "profile", "roles", "email"],
        "optionalClientScopes": [
            "address",
            "phone",
            "offline_access",
            "microprofile-jwt",
        ],
        "access": {"view": True, "configure": True, "manage": True},
        "authorizationServicesEnabled": False,
    }

    create_client(
        access_token,
        gitlab_settings,
    )


def create_default_harbor(access_token: str, base_url: str):
    harbor_settings = {
        "clientId": "harbor",
        "name": "IIIdevops Harbor Client",
        "description": "IIIdevops Harbor Client",
        "rootUrl": f"{base_url}",
        "adminUrl": "",
        "baseUrl": "",
        "surrogateAuthRequired": False,
        "enabled": True,
        "alwaysDisplayInConsole": False,
        "clientAuthenticatorType": "client-secret",
        "redirectUris": ["/c/oidc/callback"],
        "webOrigins": [],
        "notBefore": 0,
        "bearerOnly": False,
        "consentRequired": False,
        "standardFlowEnabled": True,
        "implicitFlowEnabled": False,
        "directAccessGrantsEnabled": True,
        "serviceAccountsEnabled": False,
        "publicClient": False,
        "frontchannelLogout": True,
        "protocol": "openid-connect",
        "attributes": {
            "oidc.ciba.grant.enabled": "false",
            "backchannel.logout.session.required": "true",
            "oauth2.device.authorization.grant.enabled": "false",
            "display.on.consent.screen": "false",
            "backchannel.logout.revoke.offline.tokens": "false",
        },
        "authenticationFlowBindingOverrides": {},
        "fullScopeAllowed": True,
        "nodeReRegistrationTimeout": -1,
        "defaultClientScopes": ["web-origins", "acr", "profile", "roles", "email"],
        "optionalClientScopes": [
            "address",
            "phone",
            "offline_access",
            "microprofile-jwt",
        ],
        "access": {"view": True, "configure": True, "manage": True},
    }

    create_client(
        access_token,
        harbor_settings,
    )


def create_default_sonarqube(access_token: str, base_url: str):
    sonarqube_settings = {
        "clientId": "sonarqube",
        "name": "IIIdevops SonarQube Login",
        "description": "IIIdevops SonarQube Login",
        "rootUrl": f"{base_url}/",
        "adminUrl": "",
        "baseUrl": "",
        "surrogateAuthRequired": False,
        "enabled": True,
        "alwaysDisplayInConsole": False,
        "clientAuthenticatorType": "client-secret",
        "redirectUris": [f"{base_url}/oauth2/callback/oidc"],
        "webOrigins": [],
        "notBefore": 0,
        "bearerOnly": False,
        "consentRequired": False,
        "standardFlowEnabled": True,
        "implicitFlowEnabled": False,
        "directAccessGrantsEnabled": True,
        "serviceAccountsEnabled": False,
        "publicClient": False,
        "frontchannelLogout": True,
        "protocol": "openid-connect",
        "attributes": {
            "oidc.ciba.grant.enabled": "false",
            "backchannel.logout.session.required": "true",
            "oauth2.device.authorization.grant.enabled": "false",
            "display.on.consent.screen": "false",
            "use.jwks.url": "false",
            "backchannel.logout.revoke.offline.tokens": "false",
        },
        "authenticationFlowBindingOverrides": {},
        "fullScopeAllowed": True,
        "nodeReRegistrationTimeout": -1,
        "protocolMappers": [
            {
                "name": "Groups",
                "protocol": "openid-connect",
                "protocolMapper": "oidc-group-membership-mapper",
                "consentRequired": False,
                "config": {
                    "full.path": "false",
                    "id.token.claim": "true",
                    "access.token.claim": "false",
                    "claim.name": "groups",
                    "userinfo.token.claim": "true",
                },
            }
        ],
        "defaultClientScopes": ["web-origins", "acr", "profile", "roles", "email"],
        "optionalClientScopes": [
            "address",
            "phone",
            "offline_access",
            "microprofile-jwt",
        ],
        "access": {"view": True, "configure": True, "manage": True},
    }

    create_client(
        access_token,
        sonarqube_settings,
    )


def create_default_redmine(access_token: str, base_url: str):
    redmine_settings = {
        "clientId": "redmine",
        "name": "IIIdevops Redmine Login",
        "description": "IIIdevops Redmine Login",
        "rootUrl": f"{base_url}",
        "adminUrl": "",
        "baseUrl": "",
        "surrogateAuthRequired": False,
        "enabled": True,
        "alwaysDisplayInConsole": False,
        "clientAuthenticatorType": "client-secret",
        "redirectUris": ["/oic/local_logout", "/oic/local_login"],
        "webOrigins": [],
        "notBefore": 0,
        "bearerOnly": False,
        "consentRequired": False,
        "standardFlowEnabled": True,
        "implicitFlowEnabled": False,
        "directAccessGrantsEnabled": True,
        "serviceAccountsEnabled": False,
        "publicClient": False,
        "frontchannelLogout": True,
        "protocol": "openid-connect",
        "attributes": {
            "oidc.ciba.grant.enabled": "false",
            "backchannel.logout.session.required": "true",
            "post.logout.redirect.uris": "/oic/local_logout",
            "oauth2.device.authorization.grant.enabled": "false",
            "display.on.consent.screen": "false",
            "backchannel.logout.revoke.offline.tokens": "false",
        },
        "authenticationFlowBindingOverrides": {},
        "fullScopeAllowed": True,
        "nodeReRegistrationTimeout": -1,
        "protocolMappers": [
            {
                "name": "username",
                "protocol": "openid-connect",
                "protocolMapper": "oidc-usermodel-property-mapper",
                "consentRequired": False,
                "config": {
                    "userinfo.token.claim": "true",
                    "user.attribute": "username",
                    "id.token.claim": "true",
                    "access.token.claim": "true",
                    "claim.name": "user_name",
                    "jsonType.label": "String",
                },
            },
            {
                "name": "group",
                "protocol": "openid-connect",
                "protocolMapper": "oidc-group-membership-mapper",
                "consentRequired": False,
                "config": {
                    "full.path": "false",
                    "id.token.claim": "true",
                    "access.token.claim": "true",
                    "claim.name": "member_of",
                    "userinfo.token.claim": "true",
                },
            },
        ],
        "defaultClientScopes": ["web-origins", "acr", "profile", "roles", "email"],
        "optionalClientScopes": [
            "address",
            "phone",
            "offline_access",
            "microprofile-jwt",
        ],
        "access": {"view": True, "configure": True, "manage": True},
    }

    create_client(
        access_token,
        redmine_settings,
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create client in keycloak")
    parser.add_argument("account", type=str, help="admin account of keycloak")
    parser.add_argument("password", type=str, help="admin password of keycloak")
    parser.add_argument("keycloak_base", type=str, help="keycloak base url")
    parser.add_argument(
        "option",
        type=str,
        help="what client to create",
        choices=["gitlab", "harbor", "sonarqube", "redmine"],
    )
    parser.add_argument("base_url", type=str, help="service base url")

    args = parser.parse_args()

    KEYCLOAK_URL: str = args.keycloak_base
    BASE_RESTFUL: str = f"{KEYCLOAK_URL}/admin/realms"

    token: str = get_token(args.account, args.password)

    if args.option.lower() == "gitlab":
        create_default_gitlab(token, args.base_url)
    elif args.option.lower() == "harbor":
        create_default_harbor(token, args.base_url)
    elif args.option.lower() == "sonarqube":
        create_default_sonarqube(token, args.base_url)
    elif args.option.lower() == "redmine":
        create_default_redmine(token, args.base_url)
