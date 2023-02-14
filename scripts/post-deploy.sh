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

# prints indentation
function msg() {
  echo >&2 -e "${1-}"
}

# prints usage
function usage() {
  msg
  msg "Usage: $0 <rpch_release> <hopr_release> <hopr_environment> <native_fund_amount> <hopr_fund_amount> <channel_fund_amount>"
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
#test -z "${EXIT_NODE_PUB_KEY_2:-}" && { msg "Missing EXIT_NODE_PUB_KEY_2"; usage; exit 1; }
#test -z "${EXIT_NODE_PUB_KEY_3:-}" && { msg "Missing EXIT_NODE_PUB_KEY_3"; usage; exit 1; }
#test -z "${EXIT_NODE_PUB_KEY_4:-}" && { msg "Missing EXIT_NODE_PUB_KEY_4"; usage; exit 1; }
#test -z "${EXIT_NODE_PUB_KEY_5:-}" && { msg "Missing EXIT_NODE_PUB_KEY_5"; usage; exit 1; }

# set variables
declare RPCH_RELEASE="${1}"
declare HOPR_RELEASE="${2}"
declare HOPR_ENVIRONMENT="${3}"
declare NATIVE_FUND_AMOUNT="${4}"
declare HOPR_FUND_AMOUNT="${5}"
declare CHANNEL_FUND_AMOUNT="${6}"
declare DISCOVERY_PLATFORM_ENDPOINT="$rpch_release.discovery.rpch.tech"
declare NFT_ID="16478" # we don't need to change this until next staking season
# set hoprd endpoints
declare HOPRD_API_ENDPOINT_1="http://exit-node-1-staging.staging"
declare HOPRD_API_ENDPOINT_1_EXT="http://$rpch_release.exit-node-1.rpch.tech"
#declare HOPRD_API_ENDPOINT_2="$rpch_release.exit-node-2.rpch.tech"
#declare HOPRD_API_ENDPOINT_3="$rpch_release.exit-node-3.rpch.tech"
#declare HOPRD_API_ENDPOINT_4="$rpch_release.exit-node-4.rpch.tech"
#declare HOPRD_API_ENDPOINT_5="$rpch_release.exit-node-5.rpch.tech"

# pull HOPR config and return the ENV details
echo "Pulling ENV details"
declare hoprAddress
declare nftAddress
declare stakeAddress
declare registryAddress
declare provider
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
}
getEnvDetails

# pull HOPRd nodes addresses
#echo "Pullng HOPRd nodes addresses"
#hoprdAddresses=$(
#    scurl -sX POST "http://$MANAGER_ENDPOINT/get-hoprds-addresses" \
#        -H "Content-Type: application/json" \
#        -d '{
#            "hoprdApiEndpoints": [
#                "'$HOPRD_API_ENDPOINT_1'"
#            ],
#            "hoprdApiTokens": [
#                "'$HOPRD_API_TOKEN'"
#            ]
#        }'
#)
#echo "Received hoprdAddresses: $hoprdAddresses"

hoprdAddresses='{"native": ["0x5D9839444BDA885A3a31C27aa7df9A566F04968f"],"hopr": ["16Uiu2HAm8CxNy3iS4gr3hQHSswX1RV6f8ky5Mf7UnnejiqRAGJDs"]}'

declare hoprd_native_addresses=$(jq -r .native <<< $hoprdAddresses)
declare hoprd_hopr_addresses=$(jq -r .hopr <<< $hoprdAddresses)

echo "Funding HOPRd nodes"
scurl -X POST "http://$MANAGER_ENDPOINT/fund-hoprd-nodes" \
    -H "Content-Type: application/json" \
    -d '{
          "privateKey": "'$DEPLOYER_PRIV_KEY'",
          "provider": "'$provider'",
          "hoprTokenAddress": "'$hoprAddress'",
          "nativeAmount": "'$NATIVE_FUND_AMOUNT'",
          "hoprAmount": "'$HOPR_FUND_AMOUNT'",
          "recipients": '$hoprd_native_addresses'
    }'

echo "Registering HOPRd nodes"
scurl -X POST "http://$MANAGER_ENDPOINT/register-hoprd-nodes" \
    -H "Content-Type: application/json" \
    -d '{
          "privateKey": "'$DEPLOYER_PRIV_KEY'",
          "provider": "'$provider'",
          "nftAddress": "'$nftAddress'",
          "nftId": "'$NFT_ID'",
          "stakeAddress": "'$stakeAddress'",
          "registryAddress": "'$registryAddress'",
          "peerIds": "'$hoprd_hopr_addresses'"
    }'

#echo "Open channels for HOPRd nodes"
#scurl -X POST "http://$MANAGER_ENDPOINT/open-channels" \
#    -H "Content-Type: application/json" \
#    -d '{
#          "hoprAmount": "'$CHANNEL_FUND_AMOUNT'",
#          "hoprdApiEndpoints": [
#              "'$HOPRD_API_ENDPOINT_1'",
#              "'$HOPRD_API_ENDPOINT_2'",
#              "'$HOPRD_API_ENDPOINT_3'",
#              "'$HOPRD_API_ENDPOINT_4'",
#              "'$HOPRD_API_ENDPOINT_5'"
#          ],
#          "hoprdApiTokens": [
#              "'$HOPRD_API_TOKEN'",
#              "'$HOPRD_API_TOKEN'",
#              "'$HOPRD_API_TOKEN'",
#              "'$HOPRD_API_TOKEN'",
#              "'$HOPRD_API_TOKEN'"
#          ]
#    }'

echo "Fund the funding service"
scurl -X POST "http://$MANAGER_ENDPOINT/fund-via-wallet" \
    -H "Content-Type: application/json" \
    -d '{
          "privateKey": "'$DEPLOYER_PRIV_KEY'",
          "provider": "'$provider'",
          "hoprTokenAddress": "'$hoprAddress'",
          "nativeAmount": "'$NATIVE_FUND_AMOUNT'",
          "hoprAmount": "'$HOPR_FUND_AMOUNT'",
          "recipient": "'$FUNDING_SERVICE_WALLET'"
    }'

echo "Registering nodes to discovery-platform"
scurl -X POST "http://$MANAGER_ENDPOINT/register-exit-nodes" \
    -H "Content-Type: application/json" \
    -d '{
        "discoveryPlatformEndpoint": "'$DISCOVERY_PLATFORM_ENDPOINT'",
        "hoprdApiEndpoints": [
            "'$HOPRD_API_ENDPOINT_1'"
        ],
        "hoprdApiEndpointsExt": [
            "'$HOPRD_API_ENDPOINT_1_EXT'"
        ],
        "hoprdApiTokens": [
            "'$HOPRD_API_TOKEN'"
        ],
        "exitNodePubKeys": [
            "'$EXIT_NODE_PUB_KEY_1'"
        ]
    }'
