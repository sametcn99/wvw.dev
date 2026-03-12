#!/usr/bin/env bash
set -euo pipefail

REPOS_FILE="repos.json"
OUTPUT="apps.json"
TMP_DIR=$(mktemp -d)

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install with: brew install jq"
  exit 1
fi

repos=$(jq -r '.[]' "$REPOS_FILE")
all_apps="[]"
all_categories="[]"
all_featured="[]"

for repo in $repos; do
  echo -n "Fetching $repo... "

  raw_url="https://raw.githubusercontent.com/${repo}/HEAD/apps.json"
  tmp_file="$TMP_DIR/$(echo "$repo" | tr '/' '_').json"

  if ! curl -sf "$raw_url" ${GITHUB_TOKEN:+-H "Authorization: token $GITHUB_TOKEN"} -o "$tmp_file"; then
    echo "FAILED"
    continue
  fi

  app_count=$(jq '.apps | length' "$tmp_file")
  store_name=$(jq -r '.store.name // "Unknown"' "$tmp_file")
  developer=$(jq -r '.store.developer // "Unknown"' "$tmp_file")
  echo "OK ($app_count apps from $store_name by $developer)"

  apps_with_source=$(jq --arg repo "$repo" --arg dev "$developer" --arg store "$store_name" '
    .apps | map(. + { _source: $repo, _developer: $dev, _store: $store } |
      if .developer == null then .developer = $dev else . end)
  ' "$tmp_file")
  all_apps=$(echo "$all_apps" "$apps_with_source" | jq -s '.[0] + .[1]')

  cats=$(jq '.categories // []' "$tmp_file")
  all_categories=$(echo "$all_categories" "$cats" | jq -s '.[0] + .[1] | unique_by(.id)')

  featured=$(jq '.featured // []' "$tmp_file")
  all_featured=$(echo "$all_featured" "$featured" | jq -s '.[0] + .[1]')
done

unique_apps=$(echo "$all_apps" | jq 'unique_by(.id)')
total=$(echo "$unique_apps" | jq 'length')

jq -n \
  --argjson apps "$unique_apps" \
  --argjson categories "$all_categories" \
  --argjson featured "$all_featured" \
  '{
    store: {
      name: "World Vibe Web",
      developer: "Community",
      tagline: "The distributed app store for vibe-coded projects.",
      github: "https://github.com/f/wvw.dev"
    },
    featured: $featured,
    categories: $categories,
    apps: $apps
  }' > "$OUTPUT"

rm -rf "$TMP_DIR"
echo "Done. $total apps merged into $OUTPUT"
