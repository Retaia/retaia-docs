#!/usr/bin/env bash
set -euo pipefail

declare -a versions=("v1" "v1.1" "v1.2")

for version in "${versions[@]}"; do
  expected_file="contracts/openapi-${version}.sha256"
  spec_file="api/openapi/${version}.yaml"

  if [[ ! -f "$expected_file" ]]; then
    echo "contract-drift: missing $expected_file"
    exit 1
  fi

  if [[ ! -f "$spec_file" ]]; then
    echo "contract-drift: missing $spec_file"
    exit 1
  fi

  expected="$(cat "$expected_file")"
  current="$(shasum -a 256 "$spec_file" | awk '{print $1}')"

  if [[ "$expected" != "$current" ]]; then
    echo "contract-drift: detected for $version"
    echo "expected: $expected"
    echo "current:  $current"
    echo "refresh with:"
    echo "  bash scripts/refresh-openapi-contract-hashes.sh"
    exit 1
  fi
done

echo "contract-drift: OK"
