#!/usr/bin/env bash
set -euo pipefail

EXPECTED_FILE="contracts/openapi-v1.sha256"
SPEC_FILE="api/openapi/v1.yaml"

if [[ ! -f "$EXPECTED_FILE" ]]; then
  echo "contract-drift: missing $EXPECTED_FILE"
  exit 1
fi

if [[ ! -f "$SPEC_FILE" ]]; then
  echo "contract-drift: missing $SPEC_FILE"
  exit 1
fi

EXPECTED="$(cat "$EXPECTED_FILE")"
CURRENT="$(shasum -a 256 "$SPEC_FILE" | awk '{print $1}')"

if [[ "$EXPECTED" != "$CURRENT" ]]; then
  echo "contract-drift: detected"
  echo "expected: $EXPECTED"
  echo "current:  $CURRENT"
  echo "refresh with:"
  echo "  shasum -a 256 api/openapi/v1.yaml | awk '{print \$1}' > contracts/openapi-v1.sha256"
  exit 1
fi

echo "contract-drift: OK"
