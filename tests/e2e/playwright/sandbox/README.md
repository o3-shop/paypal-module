# PayPal Sandbox Development Tooling

These scripts configure a **shop checkout** for PayPal sandbox development.
They are development helpers, not module runtime code, and are excluded from the
module package (`tests/**`).

## Typical sequence

1. Point Composer at the local module/client checkouts:

   ```bash
   SHOP_ROOT=/path/to/shop ./paypal-sandbox-setup.sh
   ```

   Then install the module in the shop container:

   ```bash
   composer run oe:install:module:paypal
   ```

2. Create the credentials file and fill in the PayPal sandbox app:

   ```bash
   cp .paypal-sandbox.env.example .paypal-sandbox.env
   $EDITOR .paypal-sandbox.env
   ./paypal-sandbox-config.sh
   ```

3. Start the public tunnel and re-register the webhook:

   ```bash
   ./paypal-sandbox-tunnel.sh
   ```

   Stop it with `./paypal-sandbox-tunnel.sh --stop`; print the current URL with
   `./paypal-sandbox-tunnel.sh --url`.

## Environment overrides

| Variable | Default | Meaning |
|---|---|---|
| `SHOP_ROOT` | two levels above the module | shop checkout on the host |
| `MODULE_PATH` | this module checkout | module path for Composer |
| `CLIENT_PATH` | `$SHOP_ROOT/local-modules/paypal-client` | client checkout |
| `SHOP_CONTAINER` | `o3shop-shop-ce-shop-1` | running shop container |
| `SHOP_WORKDIR` | `/var/www/html` | shop path inside the container |
| `SHOP_PORT` | `8080` | local shop port |
| `SANDBOX_ENV` | `.paypal-sandbox.env` in this folder | credentials file |
| `SHOP_ENV_FILE` | `$SHOP_ROOT/.env` | shop environment file changed by the tunnel |
| `WEBHOOK_SCRIPT_CONTAINER` | derived from the module path | webhook script inside the container |

The scripts assume the module is checked out as
`$SHOP_ROOT/local-modules/paypal-checkout`. If it lives elsewhere, set
`MODULE_PATH`, `CLIENT_PATH` and possibly `WEBHOOK_SCRIPT_CONTAINER`.
