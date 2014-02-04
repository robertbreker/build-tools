#!/bin/bash

set -eux

. ./functions.sh


NETWORK_NAME="internal-network"

network_uuid=$(xecommand network-list name-label="$NETWORK_NAME" --minimal)
if [[ "$network_uuid" == "" ]]; then
    network_uuid=$(xecommand network-create name-label="$NETWORK_NAME")
fi
echo "$network_uuid"
