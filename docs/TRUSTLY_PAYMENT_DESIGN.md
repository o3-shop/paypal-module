# Design: Trustly Payment via PayPal Commerce

> Status: implemented in module 2.10.3. This is the original design note; the
> executable Trustly specs live in `tests/e2e/playwright`, and the sandbox
> helper scripts in `tests/e2e/playwright/sandbox`.

## Goal
Add `oscpaypal_trustly` as a selectable alternative payment method (bank-redirect APM) in the shop, processed through `o3-shop/paypal-checkout` (module 2.10.3).

## Background
- Current fork: `local-modules/paypal-checkout` (consumed via composer path repo, symlinked at `vendor/o3-shop/paypal-checkout`), shop loads from `source/modules/osc/paypal` (copied copy).
- Trustly exists as API models in the PayPal client but no implementation in the module.
- Generic UAPM path already supports redirect APMs: `Order::_executePayment` → `Payment::doExecuteUAPMPayment` → `doCreateUAPMOrder` → `payer-action` redirect → `finalizepaypalsession` → webhook capture.
- The design is implemented in the module; the module test shop loads it via the normal module install.

## Code changes

### 1. `src/Core/PayPalDefinitions.php`
- Add constant: `public const TRUSTLY_PAYPAL_PAYMENT_ID = 'oscpaypal_trustly';`
- Add UAPM definition for Trustly:
  - countries: AT, DE, DK, EE, ES, FI, GB, LT, LV, NL, NO, SE
  - currencies: EUR, DKK, SEK, GBP, NOK
  - `isuapm => true`, `constraints => self::PAYMENT_CONSTRAINTS_UAPM`, `defaulton => true`, `paymentsource => 'trustly'`, `buttonpayment => false`, `proxycontroller => false`, `onlybrutto => false`
  - German/English `desc` with `longdesc => ''` and `longdesc_beta` image (parity with other APMs)

### 2. Eligibility wiring (gated on PayPal capability)
- `src/Core/Onboarding/Onboarding.php::saveEligibility()`: detect capability name `TRUSTLY` (ACTIVE) → set `$isTrustlyCapability`, call `saveTrustlyEligibility()`, include `'trustly' => $isTrustlyCapability` in return.
- `src/Service/ModuleSettings.php`: add `isTrustlyEligibility()`, `isLiveTrustlyEligibility()`, `isSandboxTrustlyEligibility()`, `saveTrustlyEligibility(bool)`.
- `src/Core/Config.php`: add `isLiveTrustlyEligibility()`, `isSandboxTrustlyEligibility()`.
- `metadata.php`: add settings `oscPayPalTrustlyEligibility` (bool, false) and `oscPayPalSandboxTrustlyEligibility` (bool, false).
- `src/Controller/PaymentController.php::getPaymentList()`: unset `PayPalDefinitions::TRUSTLY_PAYPAL_PAYMENT_ID` if not eligible.
- `views/admin/tpl/oscpaypalconfig.tpl`: add live and sandbox read-only rows showing Trustly eligibility.
- `views/admin/{en,de}/admin_lang.php`: add `OSC_PAYPAL_SPECIAL_PAYMENTS_TRUSTLY => 'Trustly'`.

### 3. Webhook support (PAYMENT.CAPTURE.PENDING)
- `src/Core/Webhook/Handler/PaymentCapturePendingHandler.php` (new): extends `PaymentCaptureCompletedHandler`, sets `WEBHOOK_EVENT_NAME = 'PAYMENT.CAPTURE.PENDING'`, overrides `markShopOrderPaymentStatus()` to `markOrderPaymentNotFinished()` only if not already paid; sets trans id when appropriate.
- `src/Core/Webhook/EventHandlerMapping.php`: add `'PAYMENT.CAPTURE.PENDING' => PaymentCapturePendingHandler::class`.

## Runtime behavior
Generic UAPM flow applies. Trustly return URL is `finalizepaypalsession`; capture completed/approved via webhooks; pending capture is marked not finished.

## Activation
1. Edit the module sources; the module is the source of truth.
2. Install the module into the shop as usual; no source mirroring is needed.
3. Re-activate module `osc_paypal` to ensure `oscpaypal_trustly` oxpayments row exists with delivery-set links.
4. Admin → PayPal → Check eligibility (sandbox/live) to populate Trustly capability.

## Verification
- Admin shows Trustly eligibility after check.
- Storefront (sandbox, EUR, billing country NL/SE/DE/AT etc.) shows Trustly; others hidden.
- E2E redirect flow; webhook drives status. Pending state handled.
- `./docker.sh test-all` for regressions.
