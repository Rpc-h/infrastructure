#!/bin/bash

# deployment flow
# 1. in infrastructure repo we can have branches
#   example: alpha, beta, v1, ..
# 2. set version for RPCh in application yaml
# 3. argoCD monitors this repo and deploys new version
# 4. post-deploy script needs to be run (manually)

# after deployment, this script can do the following
# 1. top-up HOPRd nodes
# 2. register HOPRd nodes (if not already registered)
# 3. make HOPRd nodes interconnect with open channels (if not already open)
# 4. top-up funding service
# 5. register exit-nodes

# prevent sourcing of this script, only allow execution
$(return >/dev/null 2>&1)
test "$?" -eq "0" && { echo "This script should only be executed." >&2; exit 1; }

# exit on errors, undefined variables, ensure errors in pipes are not hidden
set -Eeuo pipefail

# path to this file
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

# If there's a fatal error
trap 'exit 1' SIGINT SIGKILL SIGTERM ERR

# safe curl: error when response status code is >400
function scurl() {
    curl --silent --show-error --fail "$@" || exit 1
}

function strip() {
    echo $1 | tr -d ' ' | tr -d '\n'
}

# prints indentation
function msg() {
  echo >&2 -e "${1-}"
}

# prints usage
function usage() {
  msg
  msg "Usage: $0 <rpch_release> <hopr_release> <hopr_environment>"
  msg "<hoprd_native_fund_amount> <hoprd_hopr_fund_amount> <channel_fund_amount>"
  msg "<fs_native_fund_amount> <fs_hopr_fund_amount>"
  msg
  msg "Required environment variables"
  msg "------------------------------"
  msg
  msg "DEPLOYER_PRIV_KEY\t\t\tthe private key of the deployment wallet"
  msg "MANAGER_ENDPOINT\t\t\tthe endpoint to the manager"
  msg "HOPRD_API_TOKEN\t\t\tthe HOPRd API token used by these instances"
  msg "FUNDING_SERVICE_WALLET\t\t\tthe wallet of the funding service"
  msg "EXIT_NODE_PUB_KEY_1\t\t\tthe public key of exit-node 1"
  msg "EXIT_NODE_PUB_KEY_2\t\t\tthe public key of exit-node 2"
  msg "EXIT_NODE_PUB_KEY_3\t\t\tthe public key of exit-node 3"
  msg "EXIT_NODE_PUB_KEY_4\t\t\tthe public key of exit-node 4"
  msg "EXIT_NODE_PUB_KEY_5\t\t\tthe public key of exit-node 5"
}

# return early with help info when requested
([ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]) && { usage; exit 0; }

# verify parameters and environment variables
test -z "${1:-}" && { msg "Missing RPCh release"; usage; exit 1; }
test -z "${2:-}" && { msg "Missing HOPR release"; usage; exit 1; }
test -z "${3:-}" && { msg "Missing HOPR environment"; usage; exit 1; }
test -z "${4:-}" && { msg "Missing NATIVE fund amount"; usage; exit 1; }
test -z "${5:-}" && { msg "Missing HOPR fund amount"; usage; exit 1; }
test -z "${6:-}" && { msg "Missing channel fund amount"; usage; exit 1; }
test -z "${DEPLOYER_PRIV_KEY:-}" && { msg "Missing DEPLOYER_PRIV_KEY"; usage; exit 1; }
test -z "${MANAGER_ENDPOINT:-}" && { msg "Missing MANAGER_ENDPOINT"; usage; exit 1; }
test -z "${HOPRD_API_TOKEN:-}" && { msg "Missing HOPRD_API_TOKEN"; usage; exit 1; }
test -z "${FUNDING_SERVICE_WALLET:-}" && { msg "Missing FUNDING_SERVICE_WALLET"; usage; exit 1; }
test -z "${EXIT_NODE_PUB_KEY_1:-}" && { msg "Missing EXIT_NODE_PUB_KEY_1"; usage; exit 1; }
test -z "${EXIT_NODE_PUB_KEY_2:-}" && { msg "Missing EXIT_NODE_PUB_KEY_2"; usage; exit 1; }
test -z "${EXIT_NODE_PUB_KEY_3:-}" && { msg "Missing EXIT_NODE_PUB_KEY_3"; usage; exit 1; }
test -z "${EXIT_NODE_PUB_KEY_4:-}" && { msg "Missing EXIT_NODE_PUB_KEY_4"; usage; exit 1; }
test -z "${EXIT_NODE_PUB_KEY_5:-}" && { msg "Missing EXIT_NODE_PUB_KEY_5"; usage; exit 1; }

# set variables
declare RPCH_RELEASE="${1}"
declare HOPR_RELEASE="${2}"
declare HOPR_ENVIRONMENT="${3}"
declare HOPRD_NATIVE_FUND_AMOUNT="${4}"
declare HOPRD_HOPR_FUND_AMOUNT="${5}"
declare CHANNEL_FUND_AMOUNT="${6}"
declare FS_NATIVE_FUND_AMOUNT="${7}"
declare FS_HOPR_FUND_AMOUNT="${8}"
declare DISCOVERY_PLATFORM_ENDPOINT="http://discovery-platform-$RPCH_RELEASE.$RPCH_RELEASE:3020"
declare NFT_ID="26" # we don't need to change this until next staking season
# TODO: fix, this is actually NFT type index
# set hoprd endpoints
declare HOPRD_API_ENDPOINT_1="http://exit-node-1-$RPCH_RELEASE.$RPCH_RELEASE:3001"
declare HOPRD_API_ENDPOINT_1_EXT="https://$RPCH_RELEASE.exit-node-1.rpch.tech"
declare HOPRD_API_ENDPOINT_2="http://exit-node-2-$RPCH_RELEASE.$RPCH_RELEASE:3001"
declare HOPRD_API_ENDPOINT_2_EXT="https://$RPCH_RELEASE.exit-node-2.rpch.tech"
declare HOPRD_API_ENDPOINT_3="http://exit-node-3-$RPCH_RELEASE.$RPCH_RELEASE:3001"
declare HOPRD_API_ENDPOINT_3_EXT="https://$RPCH_RELEASE.exit-node-3.rpch.tech"
declare HOPRD_API_ENDPOINT_4="http://exit-node-4-$RPCH_RELEASE.$RPCH_RELEASE:3001"
declare HOPRD_API_ENDPOINT_4_EXT="https://$RPCH_RELEASE.exit-node-4.rpch.tech"
declare HOPRD_API_ENDPOINT_5="http://exit-node-5-$RPCH_RELEASE.$RPCH_RELEASE:3001"
declare HOPRD_API_ENDPOINT_5_EXT="https://$RPCH_RELEASE.exit-node-5.rpch.tech"

# pull HOPR config and return the ENV details
echo "Pulling ENV details"
declare hoprAddress
declare nftAddress
declare stakeAddress
declare registryAddress
declare provider
declare chain_id
function getEnvDetails() {
  local config=$(curl -s "https://raw.githubusercontent.com/hoprnet/hoprnet/$HOPR_RELEASE/packages/core/protocol-config.json")
  local env=$(jq -r .environments.$HOPR_ENVIRONMENT <<< $config)
  local network_id=$(jq -r .network_id <<< $env)
  local network=$(jq -r .networks.$network_id <<< $config)
  hoprAddress=$(jq -r .token_contract_address <<< $env)
  nftAddress=$(jq -r .boost_contract_address <<< $env)
  stakeAddress=$(jq -r .stake_contract_address <<< $env)
  registryAddress=$(jq -r .network_registry_contract_address <<< $env)
  provider=$(jq -r .default_provider <<< $network)
  chain_id=$(jq -r .chain_id <<< $network)
}
getEnvDetails

# pull HOPRd nodes addresses
echo "Pullng HOPRd nodes addresses"
get_hoprds_addresses_json='{
    "hoprdApiEndpoints": [
        "'$HOPRD_API_ENDPOINT_1'",
        "'$HOPRD_API_ENDPOINT_2'",
        "'$HOPRD_API_ENDPOINT_3'",
        "'$HOPRD_API_ENDPOINT_4'",
        "'$HOPRD_API_ENDPOINT_5'"
    ],
    "hoprdApiTokens": [
        "'$HOPRD_API_TOKEN'",
        "'$HOPRD_API_TOKEN'",
        "'$HOPRD_API_TOKEN'",
        "'$HOPRD_API_TOKEN'",
        "'$HOPRD_API_TOKEN'"
    ]
}'
hoprdAddresses=$(
   scurl -sX POST "$MANAGER_ENDPOINT/get-hoprds-addresses" \
       -H "Content-Type: application/json" \
       -d "$get_hoprds_addresses_json"
)
echo "Received hoprdAddresses: $hoprdAddresses"

declare hoprd_native_addresses=$(jq -r .native <<< $hoprdAddresses)
declare hoprd_hopr_addresses=$(jq -r .hopr <<< $hoprdAddresses)

echo "Funding HOPRd nodes"
fund_hoprd_nodes_json='{
    "privateKey": "'$DEPLOYER_PRIV_KEY'",
    "provider": "'$provider'",
    "hoprTokenAddress": "'$hoprAddress'",
    "nativeAmount": "'$HOPRD_NATIVE_FUND_AMOUNT'",
    "hoprAmount": "'$HOPRD_HOPR_FUND_AMOUNT'",
    "recipients": '$hoprd_native_addresses'
}'
scurl -X POST "$MANAGER_ENDPOINT/fund-hoprd-nodes" \
    -H "Content-Type: application/json" \
    -d "$fund_hoprd_nodes_json"

echo "Registering HOPRd nodes"
register_hoprd_nodes_json='{
    "privateKey": "'$DEPLOYER_PRIV_KEY'",
    "provider": "'$provider'",
    "nftAddress": "'$nftAddress'",
    "nftId": '$NFT_ID',
    "stakeAddress": "'$stakeAddress'",
    "registryAddress": "'$registryAddress'",
    "peerIds": '$hoprd_hopr_addresses'
}'
scurl -X POST "$MANAGER_ENDPOINT/register-hoprd-nodes" \
    -H "Content-Type: application/json" \
    -d "$register_hoprd_nodes_json"

# echo "Open channels for HOPRd nodes"
open_channels_json='{
    "hoprAmount": "'$CHANNEL_FUND_AMOUNT'",
    "hoprdApiEndpoints": [
        "'$HOPRD_API_ENDPOINT_1'",
        "'$HOPRD_API_ENDPOINT_2'",
        "'$HOPRD_API_ENDPOINT_3'",
        "'$HOPRD_API_ENDPOINT_4'",
        "'$HOPRD_API_ENDPOINT_5'"
    ],
    "hoprdApiTokens": [
        "'$HOPRD_API_TOKEN'",
        "'$HOPRD_API_TOKEN'",
        "'$HOPRD_API_TOKEN'",
        "'$HOPRD_API_TOKEN'",
        "'$HOPRD_API_TOKEN'"
    ]
}'
scurl -X POST "$MANAGER_ENDPOINT/open-channels" \
   -H "Content-Type: application/json" \
   -d "$open_channels_json"

echo "Fund the funding service"
fund_funding_service_json='{
    "privateKey": "'$DEPLOYER_PRIV_KEY'",
    "provider": "'$provider'",
    "hoprTokenAddress": "'$hoprAddress'",
    "nativeAmount": "'$FS_NATIVE_FUND_AMOUNT'",
    "hoprAmount": "'$FS_HOPR_FUND_AMOUNT'",
    "recipient": "'$FUNDING_SERVICE_WALLET'"
}'
scurl -X POST "$MANAGER_ENDPOINT/fund-via-wallet" \
    -H "Content-Type: application/json" \
    -d "$fund_funding_service_json"

echo "Registering nodes to discovery-platform"
register_exit_nodes_json='{
    "discoveryPlatformEndpoint": "'$DISCOVERY_PLATFORM_ENDPOINT'",
    "hoprdApiEndpoints": [
        "'$HOPRD_API_ENDPOINT_1'",
        "'$HOPRD_API_ENDPOINT_2'",
        "'$HOPRD_API_ENDPOINT_3'",
        "'$HOPRD_API_ENDPOINT_4'",
        "'$HOPRD_API_ENDPOINT_5'"
    ],
    "hoprdApiEndpointsExt": [
        "'$HOPRD_API_ENDPOINT_1_EXT'",
        "'$HOPRD_API_ENDPOINT_2_EXT'",
        "'$HOPRD_API_ENDPOINT_3_EXT'",
        "'$HOPRD_API_ENDPOINT_4_EXT'",
        "'$HOPRD_API_ENDPOINT_5_EXT'"
    ],
    "hoprdApiTokens": [
        "'$HOPRD_API_TOKEN'",
        "'$HOPRD_API_TOKEN'",
        "'$HOPRD_API_TOKEN'",
        "'$HOPRD_API_TOKEN'",
        "'$HOPRD_API_TOKEN'"
    ],
    "exitNodePubKeys": [
        "'$EXIT_NODE_PUB_KEY_1'",
        "'$EXIT_NODE_PUB_KEY_2'",
        "'$EXIT_NODE_PUB_KEY_3'",
        "'$EXIT_NODE_PUB_KEY_4'",
        "'$EXIT_NODE_PUB_KEY_5'"
    ]
}'
scurl -X POST "$MANAGER_ENDPOINT/register-exit-nodes" \
    -H "Content-Type: application/json" \
    -d "$register_exit_nodes_json"

echo "Done"
