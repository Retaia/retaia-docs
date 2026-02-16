#!/usr/bin/env bash
set -euo pipefail

declare -a versions=("v1" "v1.1" "v1.2")

for version in "${versions[@]}"; do
  spec_file="api/openapi/${version}.yaml"
  hash_file="contracts/openapi-${version}.sha256"

  if [[ ! -f "$spec_file" ]]; then
    echo "refresh-contract-hashes: missing $spec_file"
    exit 1
  fi

  shasum -a 256 "$spec_file" | awk '{print $1}' > "$hash_file"
  echo "refreshed: $hash_file"
done
