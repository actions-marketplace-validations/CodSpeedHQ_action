#!/bin/bash
# Usage: ./scripts/release.sh <major|minor|patch>
set -ex

if [ $# -ne 1 ]; then
  echo "Usage: ./release.sh <major|minor|patch>"
  exit 1
fi

# Prechecks
if [ "$(git rev-parse --abbrev-ref HEAD)" != "main" ]; then
  echo "You must be on the main branch to release"
  exit 1
fi
git diff --exit-code
pnpm format-check
pnpm lint
pnpm build

# Bump version
pnpm version $1 --git-tag-version=false
pnpm build
NEW_VERSION=$(pnpm version --json | jq '.["@codspeed/action"]' --raw-output)
MAJOR_VERSION=$(echo $NEW_VERSION | cut -d. -f1)

git add package.json dist/index.js
# Fail if there are any unstaged changes left
git diff --exit-code
git commit -m "Release v$NEW_VERSION 🚀"
git tag -fa v$NEW_VERSION -m "Release v$NEW_VERSION 🚀"
git tag -fa v$MAJOR_VERSION -m "Release v$NEW_VERSION 🚀"
git push origin v$NEW_VERSION
git push -f origin v$MAJOR_VERSION
git push --follow-tags
gh release create v$NEW_VERSION --title "v$NEW_VERSION" --generate-notes -d