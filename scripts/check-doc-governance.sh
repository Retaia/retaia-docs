#!/usr/bin/env bash
set -euo pipefail

index_file="DOCUMENT-INDEX.md"

if [[ ! -f "$index_file" ]]; then
  echo "doc-governance: missing $index_file"
  exit 1
fi

index_paths_file="$(mktemp)"
repo_docs_file="$(mktemp)"
trap 'rm -f "$index_paths_file" "$repo_docs_file"' EXIT

find . \
  -path './.git' -prune -o \
  -path './node_modules' -prune -o \
  -name '*.md' -print | sed 's#^\./##' | sort > "$repo_docs_file"

while IFS='|' read -r _ path status _rest; do
  path="$(printf '%s' "$path" | xargs | tr -d '`')"
  status="$(printf '%s' "$status" | xargs | tr -d '`')"

  [[ -z "$path" ]] && continue
  [[ "$path" == "Path" ]] && continue
  [[ "$path" == "---" ]] && continue

  case "$status" in
    NORMATIVE|NON_NORMATIVE|PREPARATORY|ROADMAP|AUDIT) ;;
    *)
      echo "doc-governance: invalid status '$status' for $path"
      exit 1
      ;;
  esac

  if grep -Fxq "$path" "$index_paths_file"; then
    echo "doc-governance: duplicate entry for $path"
    exit 1
  fi

  printf '%s\n' "$path" >> "$index_paths_file"
done < <(grep '^|' "$index_file")

while IFS= read -r doc; do
  if ! grep -Fxq "$doc" "$index_paths_file"; then
    echo "doc-governance: missing index entry for $doc"
    exit 1
  fi
done < "$repo_docs_file"

while IFS= read -r indexed; do
  if [[ ! -f "$indexed" ]]; then
    echo "doc-governance: indexed path does not exist: $indexed"
    exit 1
  fi
done < "$index_paths_file"

echo "doc-governance: OK"
