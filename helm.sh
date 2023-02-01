#!/bin/bash

NAMESPACE="staging-alpha"

helm upgrade --install discovery-platform discovery-platform --namespace ${NAMESPACE} \
  --set-string image.tag="157f259" \
  --set-string env[0].name="DB_CONNECTION_URL" \
  --set-string env[0].value="${DB_CONNECTION_URL}" \
  --set-string env[1].name="SMART_CONTRACT_ADDRESS" \
  --set-string env[1].value="0x66225dE86Cac02b32f34992eb3410F59DE416698" \
  --set-string env[2].name="HOPRD_ACCESS_TOKEN" \
  --set-string env[2].value="^^awesomeHOPRr3l4y^^" \
  --set-string env[3].name="FUNDING_SERVICE_URL" \
  --set-string env[3].value="http://funding-service.staging-alpha:3010" \
  --set-string env[4].name="SECRET_KEY" \
  --set-string env[4].value="PleaseChangeMe" \
  --set-string env[5].name="WALLET_PRIV_KEY" \
  --set-string env[5].value="0x97c7a7bdca6d4fdf1549f586971ff8744a70c5fd9b2a6d83d8dd1ca3d894a748" \
  --set-string env[6].name="PORT" \
  --set-string env[6].value="3020" \
  --set-string env[7].name="NODE_ENV" \
  --set-string env[7].value="development" \
  --set-string env[8].name="DEBUG" \
  --set-string env[8].value="hopr\*\,rpch\*\,\-\*verbose\,\-\*metrics"

helm upgrade --install funding-service funding-service --namespace ${NAMESPACE} \
  --set-string image.tag="ba605bf" \
  --set-string env[0].name="DEBUG" \
  --set-string env[0].value="hopr\*\,rpch\*\,\-\*verbose\,\-\*metrics" \
  --set-string env[1].name="SECRET_KEY" \
  --set-string env[1].value="PleaseChangeMe" \
  --set-string env[2].name="WALLET_PRIV_KEY" \
  --set-string env[2].value="0x97c7a7bdca6d4fdf1549f586971ff8744a70c5fd9b2a6d83d8dd1ca3d894a748" \
  --set-string env[3].name="DB_CONNECTION_URL" \
  --set-string env[3].value="${DB_CONNECTION_URL}" \
  --set-string env[4].name="SMART_CONTRACT_ADDRESS" \
  --set-string env[4].value="0x66225dE86Cac02b32f34992eb3410F59DE416698" \
  --set-string env[5].name="PORT" \
  --set-string env[5].value="3020"

for i in 1 2 3; do
    helm upgrade --install exit-node-${i} exit-node --namespace ${NAMESPACE} \
      --set-string rpch.image.tag="d33791b" \
      --set-string rpch.env[0].name="HOPRD_API_TOKEN" \
      --set-string rpch.env[0].value="^^awesomeHOPRr3l4y^^" \
      --set-string rpch.env[1].name="DEBUG" \
      --set-string rpch.env[1].value="hopr\*\,rpch\*\,\-\*verbose\,\-\*metrics" \
      --set-string rpch.env[2].name="RPCH_PASSWORD" \
      --set-string rpch.env[2].value="PleaseChangeMe" \
      --set-string rpch.env[3].name="HOPRD_API_ENDPOINT" \
      --set-string rpch.env[3].value="http://localhost:3001" \
      \
      --set-string hopr.image.tag="v1.90.69@sha256:edb35bec4c10c5fec5f39f55bdce103200f5936df0fd31a12b82f8ae254602a1" \
      --set-string hopr.env[0].name="HOPRD_API_TOKEN" \
      --set-string hopr.env[0].value="^^awesomeHOPRr3l4y^^" \
      --set-string hopr.env[1].name="HOPRD_API_HOST" \
      --set-string hopr.env[1].value="0.0.0.0" \
      --set-string hopr.env[2].name="HOPRD_ADMIN_HOST" \
      --set-string hopr.env[2].value="0.0.0.0" \
      --set-string hopr.env[3].name="HOPRD_ADMIN" \
      --set-string hopr.env[3].value="true" \
      --set-string hopr.env[4].name="HOPRD_API" \
      --set-string hopr.env[4].value="true" \
      --set-string hopr.env[5].name="HOPRD_INIT" \
      --set-string hopr.env[5].value="true" \
      --set-string hopr.env[6].name="HOPRD_ENVIRONMENT" \
      --set-string hopr.env[6].value="monte_rosa" \
      --set-string hopr.env[7].name="HOPRD_HOST" \
      --set-string hopr.env[7].value="0.0.0.0:9091" \
      --set-string hopr.env[8].name="HOPRD_PASSWORD" \
      --set-string hopr.env[8].value="PleaseChangeMe" \
      --set-string hopr.env[9].name="RPCH_PASSWORD" \
      --set-string hopr.env[9].value="PleaseChangeMe"
done