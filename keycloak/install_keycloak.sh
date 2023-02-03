#!/usr/bin/bash
# Script to deploy bitnami/keycloak

set -e

BASEDIR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
SCRIPT_NAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")" # https://stackoverflow.com/a/192337
LOG_FILE=/tmp/"$SCRIPT_NAME".log

# **********************************************************************************
# Functions definition
# **********************************************************************************
export nfs_dir
export deploy_mode
export gitlab_root_passwd
export admin_init_login
export admin_init_email
export admin_init_password
export keycloak_admin
export keycloak_admin_passwd
export harbor_admin_password
export keycloak_db_passwd
export rancher_ip
export gitlab_ip
export redmine_ip
export harbor_ip
export sonarqube_ip
export keycloak_ip
export iiidevops_ip
export rancher_domain_name
export gitlab_domain_name
export redmine_domain_name
export harbor_domain_name
export sonarqube_domain_name
export keycloak_domain_name
export iiidevops_domain_name
export REALM="IIIdevops"
export WAIT_ALIVE_TIMEOUT=300

function _read_env() {
  if [[ ! -e "$BASEDIR"/../env.pl ]]; then
    log "ERROR: $BASEDIR/../env.pl not set"
    exit 1
  fi

  while read -r line; do
    # skip if line not start with $
    [[ ! "$line" =~ ^\$.*$ ]] && continue
    # replace " = " to "="
    line="${line// = /=}"
    # replace ' to "
    line="${line//\'/}"
    # delete after ;
    line="${line%%;*}"
    export "${line:1}"
  done <<<"$(cat "$BASEDIR/../env.pl")"
}

function log() {
  echo -e "$1"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >>"$LOG_FILE"
}

function check_env_exist() {
  local env_name="$1"
  local env_value="${!env_name}"

  if [[ -z "$env_value" ]]; then
    log "ERROR: $env_name not set"
    exit 1
  fi
}

function check_command_exist() {
  local command_name="$1"

  if ! command -v "$command_name" &>/dev/null; then
    log "ERROR: $command_name not found"
    exit 1
  fi
}

function help() {
  echo "Usage: $SCRIPT_NAME <admin> <admin_password> <db_password> [options]"
  echo "  -h, --help      Show this help"
  echo "  -u, --update    Installing keycloak to existing cluster"
  echo "  -d, --domain    TLS domain name"
  echo "  -s, --secret    TLS secret name"
  exit 21
}

function generate_url() {
  local rc_url # Rancher
  local gl_url # GitLab
  local rm_url # Redmine
  local hb_url # Harbor
  local sq_url # SonarQube
  local kc_url # Keycloak
  local ui_url # IIIDEVOPS

  if [[ "${deploy_mode}" == "IP" ]]; then
    rc_url="${rancher_ip}:31443"
    gl_url="${gitlab_ip}:32080"
    rm_url="${redmine_ip}:32748"
    hb_url="${harbor_ip}:32443"
    sq_url="${sonarqube_ip}:31910"
    kc_url="${keycloak_ip}:32110"
    ui_url="${iiidevops_ip}:30775"
  else
    rc_url="$rancher_domain_name"
    gl_url="$gitlab_domain_name"
    rm_url="$redmine_domain_name"
    hb_url="$harbor_domain_name"
    sq_url="$sonarqube_domain_name"
    kc_url="$keycloak_domain_name"
    ui_url="$iiidevops_domain_name"
  fi

  if [[ -z "$gitlab_domain_name_tls" ]]; then
    gl_url="http://$gl_url"
  else
    gl_url="https://$gl_url"
  fi

  if [[ -z "$redmine_domain_name_tls" ]]; then
    rm_url="http://$rm_url"
  else
    rm_url="https://$rm_url"
  fi

  if [[ -z "$sonarqube_domain_name_tls" ]]; then
    sq_url="http://$sq_url"
  else
    sq_url="https://$sq_url"
  fi

  if [[ -z "$iiidevops_domain_name_tls" ]]; then
    ui_url="http://$ui_url"
  else
    ui_url="https://$ui_url"
  fi

  export RANCHER_URL="https://$rc_url"
  export GITLAB_URL="$gl_url"
  export REDMINE_URL="$rm_url"
  export HARBOR_URL="https://$hb_url"
  export SONARQUBE_URL="$sq_url"
  export KEYCLOAK_URL="https://$kc_url"
  export KEYCLOAK_RESTFUL_URL="https://$kc_url/admin/realms"
  export IIIDEVOPS_URL="$ui_url"
}

function check_alive() {
  set +e # Due to check route, we need to ignore error
  status_code=$(curl -s -k -q --max-time 5 -w '%{http_code}' -o /dev/null "$KEYCLOAK_URL"/realms/master)
  set -e # Restore error check

  if [[ $status_code != "200" ]]; then
    log "Keycloak is not alive, current status code: $status_code, until timeout second: $WAIT_ALIVE_TIMEOUT"
    sleep 10
    WAIT_ALIVE_TIMEOUT=$((WAIT_ALIVE_TIMEOUT - 10))
    if [[ $WAIT_ALIVE_TIMEOUT -le 0 ]]; then
      log "ERROR: Keycloak is not alive, current status code: $status_code"
      exit 1
    fi
    check_alive
  fi
}

function generateIssuer() {
  local CA_KEY="$nfs_dir"/deploy-config/self-signed-ca/ca.key
  local CA_CRT="$nfs_dir"/deploy-config/self-signed-ca/ca.crt
  local SERVER_KEY="$nfs_dir"/deploy-config/self-signed-ca/server.key
  local SERVER_CSR="$nfs_dir"/deploy-config/self-signed-ca/server.csr
  local SERVER_CRT="$nfs_dir"/deploy-config/self-signed-ca/server.crt
  local CLIENT_KEY="$nfs_dir"/deploy-config/self-signed-ca/client.key
  local CLIENT_CSR="$nfs_dir"/deploy-config/self-signed-ca/client.csr
  local CLIENT_CRT="$nfs_dir"/deploy-config/self-signed-ca/server.crt

  log "Checking CA cert file in: ${nfs_dir}/deploy-config"

  if [[ ! -e "$nfs_dir"/deploy-config/self-signed-ca/ca.key || ! -e "$nfs_dir"/deploy-config/self-signed-ca/ca.crt ]]; then
    mkdir -p "$nfs_dir"/deploy-config/self-signed-ca

    # Flow: From ingress nginx blog: https://awkwardferny.medium.com/20e7e38fdfca
    # Generate the CA Key and Certificate
    openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
      -subj '/C=TW/ST=TWN/L=TPE/O=IIIdevops/OU=IIIdevops/CN=IIIdevops' \
      -keyout "$CA_KEY" -out "$CA_CRT"

    # Generate the Server Key, and Certificate and Sign with the CA Certificate
    openssl req -new -newkey rsa:4096 -nodes -subj '/CN=IIIdevops' \
      -keyout "$SERVER_KEY" -out "$SERVER_CSR"
    openssl x509 -req -sha256 -days 3650 -set_serial 01 \
      -in "$SERVER_CSR" -CA "$CA_CRT" -CAkey "$CA_KEY" -out "$SERVER_CRT"

    # Generate the Client Key, and Certificate and Sign with the CA Certificate
    openssl req -new -newkey rsa:4096 -nodes -subj '/CN=IIIdevops' \
      -keyout "$CLIENT_KEY" -out "$CLIENT_CSR"
    openssl x509 -req -sha256 -days 3650 -set_serial 02 \
      -in "$CLIENT_CSR" -CA "$CA_CRT" -CAkey "$CA_KEY" -out "$CLIENT_CRT"
  fi

  local ISSUER="$BASEDIR/values/CA-issuer.yaml"
  local ISSUER_YAML
  local ISSUER_YAML_FILE="$nfs_dir"/deploy-config/self-signed-ca/CA-issuer.yaml
  ISSUER_YAML=$(cat "$ISSUER")
  # shellcheck disable=SC2002
  ISSUER_YAML="${ISSUER_YAML//{{tls_crt\}\}/$(cat "$CA_CRT" | base64 -w0)}"
  # shellcheck disable=SC2002
  ISSUER_YAML="${ISSUER_YAML//{{tls_key\}\}/$(cat "$CA_KEY" | base64 -w0)}"
  echo "$ISSUER_YAML" >"$ISSUER_YAML_FILE"

  log "[DONE] Generated CA issuer and secret file in: $ISSUER_YAML_FILE"
  kubectl apply -f "$ISSUER_YAML_FILE"
  log "Applied CA issuer and secret"
}

function generateYAML() {
  check_env_exist keycloak_admin
  check_env_exist keycloak_admin_passwd
  check_env_exist keycloak_db_passwd

  local BASE_YAML
  if [[ "${deploy_mode}" == "IP" ]]; then
    BASE_YAML="$BASEDIR/values/ip.yaml"
    _certificate="$(cat "$BASEDIR/values/ip-certificate.yaml")"
    _certificate="${_certificate//<KEYCLOAK_IP>/$keycloak_ip}"

    echo "$_certificate" >"$KEYCLOAK_BASEDIR/ip-certificate.yaml"
    log "[DONE] Generated certificate file in: $KEYCLOAK_BASEDIR/ip-certificate.yaml"

    kubectl apply -f "$KEYCLOAK_BASEDIR/ip-certificate.yaml"
    log "Applied ip certificate"
  else
    BASE_YAML="$BASEDIR/values/dns-base.yaml"
  fi

  _values="$(cat "$BASE_YAML")"
  _values="${_values//<ADMIN_USER>/$keycloak_admin}"
  _values="${_values//<ADMIN_PASSWORD>/$keycloak_admin_passwd}"
  _values="${_values//<DB_PASSWORD>/$keycloak_db_passwd}"

  if [[ "${deploy_mode}" == "DNS" ]]; then
    if [[ "$DOMAIN_NAME" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]; then
      log "ERROR: $DOMAIN_NAME is not a domain name, could not use any IPv4 address as domain name"
      exit 1
    fi

    if [[ -z $DOMAIN_NAME ]]; then
      log "ERROR: DOMAIN_NAME is empty, please check environment variable"
      help
      exit 1
    fi

    if [[ -z $SECRET ]]; then
      _ingress="$(cat "$BASEDIR/values/tls-cert-manager.yaml")"
      _ingress="${_ingress//<CERT-ISSUER>/iiidevops-ca-issuer}"
      # self-signed certificate is not allowed to other service, so we use cert-manager instead
      # _ingress="$(cat "$BASEDIR/values/tls-self-signed.yaml")"
    else
      _ingress="$(cat "$BASEDIR/values/tls-secret.yaml")"
      _ingress="${_ingress//<SECRET>/$SECRET}"
    fi

    _ingress="${_ingress//<DOMAIN_NAME>/$DOMAIN_NAME}"
  fi

  echo "$_values" >"$KEYCLOAK_BASEDIR/values.yaml"
  echo "$_ingress" >>"$KEYCLOAK_BASEDIR/values.yaml"

  log "[DONE] Generated values in: $KEYCLOAK_BASEDIR/values.yaml"
}

function configureKeycloak() {
  log "************************************"
  log " Configure Keycloak realm"
  log " Modified from: https://github.com/thomassuedbroecker/keycloak-create-realm-bash/blob/main/scripts/local-configure-keycloak.sh"
  log "************************************"

  # Set the needed parameter
  USER="${keycloak_admin}"
  PASSWORD="${keycloak_admin_passwd}"
  GRANT_TYPE=password
  CLIENT_ID=admin-cli

  # Get the token
  set -x
  access_token=$(curl -s -k -d "client_id=$CLIENT_ID" -d "username=$USER" -d "password=$PASSWORD" -d "grant_type=$GRANT_TYPE" "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" | sed -n 's|.*"access_token":"\([^"]*\)".*|\1|p')
  set +x

  if [ "$access_token" = "" ]; then
    log "------------------------------------------------------------------------"
    log "Error:"
    log "======"
    log ""
    log "It seems there is a problem to get the Keycloak access token: ($access_token)"
    log "The script exits here!"
    log ""
    log "------------------------------------------------------------------------"
    exit 1
  fi

  TEMPLATE_FILE="$BASEDIR"/template/default-realm.json.tmpl
  REALMS_JSON="$KEYCLOAK_BASEDIR/realms-settings.json"
  TEMPLATE=$(cat "$TEMPLATE_FILE")

  for i in {1..100}; do
    local uuid
    uuid=$(uuidgen)
    TEMPLATE="${TEMPLATE//{{UUID_$i\}\}/$uuid}"
  done

  echo "$TEMPLATE" >"$REALMS_JSON"
  log "[DONE] Generated realms settings in: $REALMS_JSON"

  # Create the realm in Keycloak
  log "------------------------------------------------------------------------"
  log "Create the realm in Keycloak"
  log "------------------------------------------------------------------------"
  log ""

  result=$(curl -s -k -d @"$REALMS_JSON" -H "Content-Type: application/json" -H "Authorization: bearer $access_token" "$KEYCLOAK_RESTFUL_URL")

  if [ "$result" = "" ]; then
    log "------------------------------------------------------------------------"
    log "The realm is created. "
    log "Open following link in your browser:"
    log "$KEYCLOAK_URL/admin/master/console/#/$REALM"
    log "------------------------------------------------------------------------"
  elif [[ "$result" == '{"errorMessage":"Conflict detected. See logs for details"}' ]]; then
    log "------------------------------------------------------------------------"
    log "The realm is already created."
    log "Open following link in your browser:"
    log "$KEYCLOAK_URL/admin/master/console/#/$REALM"
  else
    log "------------------------------------------------------------------------"
    log "Error:"
    log "======"
    log "It seems there is a problem with the realm creation: $result"
    log "The script exits here!"
    log ""
    exit 1
  fi
}

function main() {
  log "----------------------------------------"
  log "$(TZ='Asia/Taipei' date)"

  check_command_exist "curl"

  set +e # Due to check route, we need to ignore error
  status_code=$(curl -s -k -q --max-time 5 -w '%{http_code}' -o /dev/null "$KEYCLOAK_URL"/realms/master)
  set -e # Restore error check

  if [[ $status_code == "200" ]]; then
    log "Keycloak is already installed, skip installation"
    exit 0
  fi

  if [[ "$UPDATE" == 1 ]]; then
    log "Adding keycloak..."
  else
    log "Deploying keycloak..."
    log "Deploy mode: ${deploy_mode}"

    generateIssuer
    generateYAML
    log "----------------------------------------"
    set -x
    helm install keycloak -f "$KEYCLOAK_BASEDIR"/values.yaml "$BASEDIR"/keycloak-13.0.2.tgz
    set +x
    log "----------------------------------------"
    log "Checking URL: $KEYCLOAK_URL/realms/master"
    check_alive
    log "----------------------------------------"
    log "Keycloak is now ready"
    log "Starting setting initial data..."
    configureKeycloak
    log "----------------------------------------"
    log "Current base: $KEYCLOAK_URL/admin/realms"
    set -x
    python3 "$BASEDIR"/create_client.py "$keycloak_admin" "$keycloak_admin_passwd" "$KEYCLOAK_URL" \
      gitlab "$GITLAB_URL"
    python3 "$BASEDIR"/create_client.py "$keycloak_admin" "$keycloak_admin_passwd" "$KEYCLOAK_URL" \
      harbor "$HARBOR_URL"
    python3 "$BASEDIR"/create_client.py "$keycloak_admin" "$keycloak_admin_passwd" "$KEYCLOAK_URL" \
      sonarqube "$SONARQUBE_URL"
    python3 "$BASEDIR"/create_client.py "$keycloak_admin" "$keycloak_admin_passwd" "$KEYCLOAK_URL" \
      redmine "$REDMINE_URL"
    python3 "$BASEDIR"/create_client.py "$keycloak_admin" "$keycloak_admin_passwd" "$KEYCLOAK_URL" \
      iiidevops "$IIIDEVOPS_URL"
    set +x
    log "[DONE] Clients initialized success!"
    log "----------------------------------------"
    # GitLab user
    set -x
    python3 "$BASEDIR"/create_group.py "$keycloak_admin" "$keycloak_admin_passwd" "$KEYCLOAK_URL" \
      --name sonar-administrators
    python3 "$BASEDIR"/create_user.py "$keycloak_admin" "$keycloak_admin_passwd" "$KEYCLOAK_URL" \
      --username root --email admin@example.com \
      --firstname 系統管理員 --lastname 系統管理員 \
      --password "$gitlab_root_passwd" \
      --groups sonar-administrators
    # IIIdevops admin, will create in API startup
    # python3 "$BASEDIR"/create_user.py "$keycloak_admin" "$keycloak_admin_passwd" "$KEYCLOAK_URL" \
    #   --username "$admin_init_login" --email "$admin_init_email" \
    #   --firstname 系統管理員 --lastname 系統管理員 \
    #   --password "$admin_init_password" \
    #   --groups sonar-administrators
    set +x
    log "[DONE] Users initialized success!"
    log "----------------------------------------"
    log "Setting GitLab"
    gitlab_token="$(python3 "$BASEDIR"/get_token.py "$keycloak_admin" "$keycloak_admin_passwd" "$KEYCLOAK_URL" gitlab)"
    gitlab_deploy_yaml_tmpl="$BASEDIR"/../gitlab/gitlab-deployment.yml.tmpl
    gitlab_deploy_yaml_modified_tmpl="$BASEDIR"/../gitlab/gitlab-deployment-keycloak.yml.tmpl
    if [[ -f $gitlab_deploy_yaml_tmpl ]]; then
      gitlab_yaml_modified=$(cat "$gitlab_deploy_yaml_tmpl")
      gitlab_yaml_modified="${gitlab_yaml_modified//{{keycloak_secret\}\}/$gitlab_token}"
      gitlab_yaml_modified="${gitlab_yaml_modified//{{keycloak_url\}\}/$KEYCLOAK_URL}"
      echo "$gitlab_yaml_modified" >"$gitlab_deploy_yaml_modified_tmpl"
      set +e
      diff "$gitlab_deploy_yaml_tmpl" "$gitlab_deploy_yaml_modified_tmpl"
      set -e
      log "GitLab configured, waiting to deploy"
    else
      log "GitLab deployment template not found, exit"
      exit 1
    fi
    log "[DONE] GitLab configured success!"
    log "----------------------------------------"
    log "Setting Redmine"
    log "[SKIP] Redmine settings skipped"
    # Redmine -> Don't deploy
    # log "Copying redmine plugins, don't setup plugins due to settings conflict."
    # log "cp -r \"$BASEDIR\"/redmine_plugins/* \"${nfs_dir:-}\"/redmine-plugins"
    # cp -r "$BASEDIR"/redmine_plugins/* "${nfs_dir:-}"/redmine-plugins
    log "----------------------------------------"
    log "Setting Sonarqube"
    if [[ ! -e "${nfs_dir}"/sonarqube-plugins/sonar-auth-oidc-plugin-2.1.1.jar ]]; then
      log "Copying sonarqube plugins"
      cp -r "$BASEDIR"/sonarqube_plugins/* "${nfs_dir}"/sonarqube-plugins
    fi
    log "[DONE] Sonarqube configured success!"
    log "----------------------------------------"
    log "Setting Harbor"
    python3 "$BASEDIR"/set_harbor.py "$keycloak_admin" "$keycloak_admin_passwd" "$KEYCLOAK_URL" \
      --hb_password "$harbor_admin_password" --hb_url "$HARBOR_URL"
    log "[DONE] Harbor configured success!"
  fi
}

# **********************************************************************************
# Main entry point
# **********************************************************************************

_read_env
generate_url

while [[ "$#" -gt 0 ]]; do
  case $1 in
  -u | --update) UPDATE=1 ;;
  -d | --domain)
    DOMAIN_NAME="$2"
    shift
    ;;
  -s | --secret)
    SECRET="$2"
    shift
    ;;
  -h | --help) help ;;
  *) echo "Unknown parameter passed: $1" && help ;;
  esac
  shift
done

if [[ -z "$DOMAIN_NAME" ]]; then
  DOMAIN_NAME="$keycloak_domain_name"
fi

mkdir -p "$nfs_dir"/deploy-config/keycloak
KEYCLOAK_BASEDIR="$nfs_dir/deploy-config/keycloak"

main
