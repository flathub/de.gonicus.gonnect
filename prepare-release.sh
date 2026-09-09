#!/usr/bin/env bash
for cmd in sed git curl uv cargo; do
    hash $cmd 2>/dev/null || { echo >&2 "error: $cmd not found"; exit 1; }
done

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Parsing command line
VERSION=

while [[ "$#" -gt 0 ]]; do
    case $1 in
        *)
            if [ -z "$VERSION" ]; then
                VERSION="$1"
            else
               echo "Unknown parameter \"$1\""
               help
               exit 1
            fi 
            shift
            ;;
    esac
done

if [ -z "$VERSION" ]; then
    echo "A version must be set, e.g. v2.5.0-beta.5"
    exit 1
fi

REPO_URL=https://github.com/gonicus/gonnect

TMPDIR=$(mktemp -d)
trap '{ rm -rf -- "$TMPDIR"; }' EXIT

echo "* Checking out..."
git clone --depth 1 --branch  "$VERSION" "$REPO_URL" "$TMPDIR"
COMMIT_HASH=$(cd "$TMPDIR"; git rev-parse HEAD)

# Copy files from repo
echo "* Copy files over..."
cp "$TMPDIR/resources/flatpak/patches/"* "$SCRIPT_DIR/patches"
cp "$TMPDIR/resources/flatpak/de.gonicus.gonnect.yml" "$SCRIPT_DIR/"

echo "* Updating version in Flatpak definition..."
yq -i ".modules[] |= select(.name==\"gonnect\").sources[0] = {\"type\": \"git\", \"url\": \"${REPO_URL}.git\", \"tag\": \"$VERSION\", \"commit\": \"$COMMIT_HASH\"}" "$SCRIPT_DIR/de.gonicus.gonnect.yml"
