#!/bin/bash
# Applies PayPal Sandbox credentials from ./.paypal-sandbox.env into the
# running shop's module configuration, and turns on sandbox mode.
#
# Usage:
#   ./paypal-sandbox-config.sh
#
# The credentials file is gitignored and never committed. This script talks to
# the running shop container and writes module settings via the shop's own
# bootstrap (config is cached, so we clear it afterwards).
#
# Environment overrides:
#   SHOP_CONTAINER   shop container name (default o3shop-shop-ce-shop-1)
#   SHOP_WORKDIR     shop path inside the container (default /var/www/html)
#   SANDBOX_ENV      credentials file (default .paypal-sandbox.env next to this script)
#   SHOP_PORT         shop port for the admin hint (default 8080)

set -euo pipefail

SCRIPT_DIR=$(cd -P "$(dirname "$0")" && pwd)
ENV_FILE="${SANDBOX_ENV:-$SCRIPT_DIR/.paypal-sandbox.env}"
CONTAINER="${SHOP_CONTAINER:-o3shop-shop-ce-shop-1}"
SHOP_WORKDIR="${SHOP_WORKDIR:-/var/www/html}"
SHOP_PORT="${SHOP_PORT:-8080}"
SHOP_URL="${SHOP_URL:-http://localhost:$SHOP_PORT}"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: $ENV_FILE not found. Copy .paypal-sandbox.env.example (next to this script) and fill it in." >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a; source "$ENV_FILE"; set +a

: "${OSC_PAYPAL_SANDBOX_CLIENT_ID:?Set OSC_PAYPAL_SANDBOX_CLIENT_ID in .paypal-sandbox.env}"
: "${OSC_PAYPAL_SANDBOX_CLIENT_SECRET:?Set OSC_PAYPAL_SANDBOX_CLIENT_SECRET in .paypal-sandbox.env}"

for v in OSC_PAYPAL_SANDBOX_CLIENT_ID OSC_PAYPAL_SANDBOX_CLIENT_SECRET \
         OSC_PAYPAL_SANDBOX_MERCHANT_ID OSC_PAYPAL_SANDBOX_WEBHOOK_ID; do
  if [ -z "${!v}" ]; then
    echo "WARNING: $v is empty — skipping."
  fi
done

echo "Applying sandbox credentials to module osc_paypal in $CONTAINER ..."

# Pass the variable *names* only: docker reads the values from this process's
# environment, so the client secret never appears on the docker/ps command line.
# Run as www-data so the module log is created by the web-server user instead of
# root (a root-owned source/log/paypal/*.log breaks later checkouts).
if ! OUTPUT=$(docker exec -u www-data \
  -e SHOP_WORKDIR \
  -e OSC_PAYPAL_SANDBOX_CLIENT_ID \
  -e OSC_PAYPAL_SANDBOX_CLIENT_SECRET \
  -e OSC_PAYPAL_SANDBOX_MERCHANT_ID \
  -e OSC_PAYPAL_SANDBOX_WEBHOOK_ID \
  "$CONTAINER" php -r '
$root = getenv("SHOP_WORKDIR") ?: "/var/www/html";
require $root . "/vendor/autoload.php";
require $root . "/source/bootstrap.php";
$settings = \OxidEsales\EshopCommunity\Internal\Container\ContainerFactory::getInstance()
    ->getContainer()->get(\OxidSolutionCatalysts\PayPal\Service\ModuleSettings::class);
$settings->save("oscPayPalSandboxMode", true);
$settings->save("oscPayPalSandboxClientId", getenv("OSC_PAYPAL_SANDBOX_CLIENT_ID") ?: "");
$settings->save("oscPayPalSandboxClientSecret", getenv("OSC_PAYPAL_SANDBOX_CLIENT_SECRET") ?: "");
$settings->save("oscPayPalSandboxClientMerchantId", getenv("OSC_PAYPAL_SANDBOX_MERCHANT_ID") ?: "");
$settings->save("oscPayPalSandboxWebhookId", getenv("OSC_PAYPAL_SANDBOX_WEBHOOK_ID") ?: "");
echo "isSandbox: ".var_export($settings->isSandbox(), true)."\n";
echo "clientId: ".(string)$settings->getClientId()."\n";
echo "merchant: ".(string)$settings->getMerchantId()."\n";
echo "webhook: ".(string)$settings->getWebhookId()."\n";
' 2>&1); then
  echo "$OUTPUT" >&2
  echo "ERROR: applying the sandbox credentials failed." >&2
  exit 1
fi

echo "$OUTPUT" | grep -v "Deprecated:" || true

echo "Clearing shop cache ..."
docker exec -u www-data "$CONTAINER" "$SHOP_WORKDIR/bin/oe-console" oe:cache:clear 2>&1 | grep -v "Deprecated:" || true

echo
echo "Verify in admin: Extensions > Modules > PayPal Checkout"
echo "  $SHOP_URL/admin/"
