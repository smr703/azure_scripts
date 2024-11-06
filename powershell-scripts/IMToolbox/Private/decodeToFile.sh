#!/usr/bin/env bash

base64str="${content}"
location="${path}"

[ -z "$base64str" ] && echo "No base64 provided" && exit 1
[ -z "$location" ] && echo "No location provided" && exit 1

echo "$base64str" | base64 -d > "$location"
