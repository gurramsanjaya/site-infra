#!/usr/bin/env bash
set -eo pipefail

: ${TERRAFORM_BIN:=tofu}
: ${NGINX_GATEWAY_API_VER:=v2.6.7}
: ${NGINX_GATWAY_NS:=nginx-gateway}
: ${CERT_MANAGER_NS:=cert-manager}
: ${INFRA_NS:=infra}
: ${SKIP_DRY_RUN_CHECK:=false}
# increase this as needed
: ${WAIT_BTW_INSTALL:=150s}

ORIGINAL_DIR=""

## --- Function Block ---

cleanup() {
    local exit_code=$?
    trap - EXIT TERM INT HUP
    if [[ -n "$ORIGINAL_DIR" && -d "$ORIGINAL_DIR" ]]; then
        cd -- "$ORIGINAL_DIR" &> /dev/null
    fi
    echo "script exiting with code: $exit_code"
    exit "$exit_code"
}

function check_continue() {
  read -p "Continue (y/n)? " CONTINUE
  if ! [[ $CONTINUE =~ ^[[:space:]]*[yY] ]]; then
    echo "quiting..."
    exit 0
  fi
}

## Careful passing any complex command with redirection or other fancy things (hint: it won't work)
function with_dry_run() {
    if [[ $SKIP_DRY_RUN_CHECK != "true" ]]; then
        "$@" --dry-run
        check_continue
    fi
    "$@"
    echo "Waiting for ${WAIT_BTW_INSTALL}..."
    sleep $WAIT_BTW_INSTALL

}

## --- Main Block ---

# setup the trap
trap cleanup EXIT TERM INT HUP

# switch to script directory
ORIGINAL_DIR=${PWD}
SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

# set basic kubectl config
export KUBERC=off
export KUBECONFIG=$(readlink -f "${PWD}/../.kube/config")
if ! (readlink -e "$KUBECONFIG" > /dev/null ); then 
  # refresh from terraform
  $TERRAFORM_BIN -chdir=../terraform output -show-sensitive -raw config_raw > "$KUBECONFIG"
fi
# cross check once more 
readlink -e $KUBECONFIG > /dev/null

# build deps for the wrapper charts
helm dependency build cert-manager-wrapper/
helm dependency build nginx-gateway-fabric-wrapper/

# install gateway API crds
echo "Installing gateway API crds"
kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=${NGINX_GATEWAY_API_VER}" | kubectl apply --server-side=true -f -

# need to explicitly install this since dependent chart crd/ folders don't get installed by helm
echo "Installing nginx-gateway-fabric API crds"
kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd?ref=${NGINX_GATEWAY_API_VER}" | kubectl apply --server-side=true -f -

# install the charts with an extra dry-run just for extra caution
# might need to wait a bit between each install, the next one is dependent on the previous one being up and running and so on...
echo "Installing helm charts"
with_dry_run helm install nginx-gateway-fabric nginx-gateway-fabric-wrapper/ -n $NGINX_GATWAY_NS --create-namespace
with_dry_run helm install cert-manager cert-manager-wrapper/ -n $CERT_MANAGER_NS --create-namespace
with_dry_run helm install infra infra/ -n $INFRA_NS --create-namespace -f infra/values-override.yaml
