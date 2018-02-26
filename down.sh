#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

source state/env.sh
: ${ESX_USERNAME:?"!"}
: ${ESX_PASSWORD:?"!"}
: ${ESX_HOST:?"!"}
: ${ESX_THUMBPRINT:?"!"}
: ${ESX_DATASTORE:?"!"}
: ${ESX_NETWORK:?"!"}
: ${VM_NAME:?"!"}
: ${CPUS:?"!"}
: ${MEMORY_MB:?"!"}
: ${DISK_SIZE:?"!"}

mkdir -p bin
if ! [ -f bin/govc ]; then
  curl -L https://github.com/vmware/govmomi/releases/download/v0.15.0/govc_darwin_amd64.gz > bin/govc.gz
  gzip -d bin/govc.gz
  chmod +x bin/govc
fi

export GOVC_INSECURE=1
export GOVC_URL=$ESX_HOST
export GOVC_USERNAME=$ESX_USERNAME
export GOVC_PASSWORD=$ESX_PASSWORD
export GOVC_DATASTORE=$ESX_DATASTORE
export GOVC_NETWORK=$ESX_NETWORK
#export GOVC_RESOURCE_POOL='*/Resources'

if bin/govc vm.info $VM_NAME; then
  bin/govc vm.destroy $VM_NAME
fi

#if bin/govc datastore.ls esx-auto.iso >/dev/null; then
#  bin/govc datastore.rm esx-auto.iso;
#fi

