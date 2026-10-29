#!/bin/bash
# Configures a shop checkout to use the local PayPal module/client path
# repositories for development.
#
# Run from the host: when composer is not on PATH, the script re-executes itself
# inside the shop container as the current user, so composer.json keeps its
# ownership. Running it inside the container also works.
#
# The two path repositories are deliberately NOT committed: the module/client
# folders are local development checkouts, and Composer 2.2 fails on a literal
# path repository whose directory does not exist. Run this script once in a
# checkout that has the module and client; it writes the repositories to the
# local, uncommitted shop composer.json.
#
# Environment overrides:
#   SHOP_ROOT       shop checkout (default: two levels above the module)
#   MODULE_PATH     module checkout (default: this repository)
#   CLIENT_PATH     client checkout (default: $SHOP_ROOT/local-modules/paypal-client)
#   SHOP_CONTAINER  shop container name (default o3shop-shop-ce-shop-1)
#   SHOP_WORKDIR    shop path inside the container (default /var/www/html)
#
# After that, inside the container:
#   composer run oe:install:module:paypal
# installs the module into the shop.

set -euo pipefail

SCRIPT_DIR=$(cd -P "$(dirname "$0")" && pwd)
SCRIPT_PATH="$SCRIPT_DIR/$(basename "$0")"
MODULE_ROOT=$(cd "$SCRIPT_DIR/../../../.." && pwd)
SHOP_ROOT="${SHOP_ROOT:-$(cd "$MODULE_ROOT/../.." && pwd)}"
MODULE_PATH="${MODULE_PATH:-$MODULE_ROOT}"
CLIENT_PATH="${CLIENT_PATH:-$SHOP_ROOT/local-modules/paypal-client}"
CONTAINER="${SHOP_CONTAINER:-o3shop-shop-ce-shop-1}"
SHOP_WORKDIR="${SHOP_WORKDIR:-/var/www/html}"

relpath() {
  python3 -c 'import os, sys; print(os.path.relpath(sys.argv[2], sys.argv[1]))' "$1" "$2"
}

if ! command -v composer >/dev/null 2>&1; then
  MODULE_REL=$(relpath "$SHOP_ROOT" "$MODULE_PATH")
  CLIENT_REL=$(relpath "$SHOP_ROOT" "$CLIENT_PATH")
  SCRIPT_REL=$(relpath "$SHOP_ROOT" "$SCRIPT_PATH")
  exec docker exec -u "$(id -u):$(id -g)" \
    -e COMPOSER_HOME=/tmp/composer \
    -e SHOP_ROOT="$SHOP_WORKDIR" \
    -e MODULE_PATH="$SHOP_WORKDIR/$MODULE_REL" \
    -e CLIENT_PATH="$SHOP_WORKDIR/$CLIENT_REL" \
    -e PAYPAL_MODULE_VERSION="${PAYPAL_MODULE_VERSION:-}" \
    -e PAYPAL_CLIENT_VERSION="${PAYPAL_CLIENT_VERSION:-}" \
    -w "$SHOP_WORKDIR" "$CONTAINER" \
    bash "$SHOP_WORKDIR/$SCRIPT_REL"
fi

cd "$SHOP_ROOT"

for dir in "$MODULE_PATH" "$CLIENT_PATH"; do
  if [ ! -d "$dir" ]; then
    echo "ERROR: $dir not found; check out the PayPal module/client repositories there first." >&2
    exit 1
  fi
done

# The path repositories need an explicit version. Read the module version from its
# metadata.php (the source of truth), and the client version from the checkout's
# newest tag; both can be overridden with PAYPAL_MODULE_VERSION / PAYPAL_CLIENT_VERSION.
MODULE_VERSION="${PAYPAL_MODULE_VERSION:-}"
CLIENT_VERSION="${PAYPAL_CLIENT_VERSION:-}"

# When running on the host with PHP available, prefer the module metadata on disk.
# If reading it fails or gives nothing, try to read inside the container so the
# environment matches the shop; as a last resort read an exact tag from git.
if [ -z "$MODULE_VERSION" ] && command -v php >/dev/null 2>&1; then
  MODULE_VERSION=$(
    PAYPAL_MODULE_METADATA="$MODULE_PATH/metadata.php" php -r '
      $sMetadataVersion = null;
      $aModule = null;
      ob_start();
      include getenv("PAYPAL_MODULE_METADATA");
      ob_end_clean();
      echo is_array($aModule) && isset($aModule["version"]) ? $aModule["version"] : "";
    ' 2>/dev/null
  ) || MODULE_VERSION=""
fi

if [ -z "$MODULE_VERSION" ] && command -v docker >/dev/null 2>&1; then
  MODULE_REL=$(relpath "$SHOP_ROOT" "$MODULE_PATH")
  MODULE_VERSION=$(docker exec -u "$(id -u):$(id -g)" \
    -e MODULE_METADATA="$SHOP_WORKDIR/$MODULE_REL/metadata.php" \
    -w "$SHOP_WORKDIR" "$CONTAINER" php -r '
    $sMetadataVersion = null;
    $aModule = null;
    ob_start();
    include getenv("MODULE_METADATA");
    ob_end_clean();
    echo is_array($aModule) && isset($aModule["version"]) ? $aModule["version"] : "";
  ' 2>/dev/null) || MODULE_VERSION=""
fi

if [ -z "$MODULE_VERSION" ]; then
  MODULE_VERSION=$(git -C "$MODULE_PATH" describe --tags --exact-match 2>/dev/null) || MODULE_VERSION=""
  MODULE_VERSION="${MODULE_VERSION#v}"
fi

if [ -z "$CLIENT_VERSION" ]; then
  CLIENT_VERSION=$(git -C "$CLIENT_PATH" describe --tags --exact-match 2>/dev/null) || CLIENT_VERSION=""
  CLIENT_VERSION="${CLIENT_VERSION#v}"
fi

if [ -z "$MODULE_VERSION" ] || [ -z "$CLIENT_VERSION" ]; then
  echo "ERROR: could not determine the version to pin for the PayPal path repositories." >&2
  echo "The checkout must be at an exact tag, or set PAYPAL_MODULE_VERSION and PAYPAL_CLIENT_VERSION and re-run." >&2
  exit 1
fi

MODULE_REL=$(relpath "$SHOP_ROOT" "$MODULE_PATH")
CLIENT_REL=$(relpath "$SHOP_ROOT" "$CLIENT_PATH")
composer config repositories.paypal-checkout \
  "{\"type\":\"path\",\"url\":\"$MODULE_REL\",\"options\":{\"symlink\":true,\"versions\":{\"o3-shop/paypal-checkout\":\"$MODULE_VERSION\"}}}"
composer config repositories.paypal-client \
  "{\"type\":\"path\",\"url\":\"$CLIENT_REL\",\"options\":{\"symlink\":true,\"versions\":{\"o3-shop/paypal-client\":\"$CLIENT_VERSION\"}}}"

echo "Configured local PayPal path repositories in composer.json (uncommitted)."
echo "Next (in the container): composer run oe:install:module:paypal"
