import { test, expect } from '@playwright/test';
import { O3CheckoutHelper } from '../../helpers/O3CheckoutHelper';
import { DatabaseHelper } from '../../helpers/DatabaseHelper';

const PRODUCT_ID = process.env.TRUSTLY_PRODUCT_ID || '01c9499c21914ae7de1b2412ea4b019f';
const TRUSTLY_ID = 'oscpaypal_trustly';
const GERMANY = 'a7c40f631fc920687.20179984';
const SWITZERLAND = process.env.TRUSTLY_CH_COUNTRY_ID || 'a7c40f6321c6f6109.43859248';

const guestAddress = (suffix, countryId) => ({
    email: `guest-${suffix}-${Date.now()}@example.test`,
    firstName: 'Erika',
    lastName: 'Mustermann',
    street: 'Musterstraße',
    streetNo: '1',
    zip: '12345',
    city: 'Musterstadt',
    countryId,
});

test.use({
    extraHTTPHeaders: {
        'ngrok-skip-browser-warning': 'true',
    },
});

// The CH case toggles a global shop setting; keep the file serial.
test.describe.configure({ mode: 'serial' });

/**
 * Trustly (oscpaypal_trustly) storefront visibility:
 * a Trustly country shows the payment method, a non-Trustly country hides it.
 */
test.describe('Trustly payment method visibility', () => {
    test('shown for a Trustly country (DE) on the payment step', async ({ page }) => {
        test.skip(process.env.PAYPAL_E2E !== '1', 'requires PAYPAL_E2E=1 with the PayPal module and sandbox');

        const checkout = new O3CheckoutHelper(page);
        await checkout.setupAndGoto(PRODUCT_ID, guestAddress('trustly-de', GERMANY));

        const trustly = checkout.paymentRadio(TRUSTLY_ID);
        await expect(trustly, 'oscpaypal_trustly must be offered on the payment step').toHaveCount(1);
        await expect(trustly).toBeVisible();

        // A neighbouring PayPal payment proves the payment list rendered, so a
        // missing Trustly would be module-specific.
        await expect(checkout.paymentRadio('oscpaypal')).toHaveCount(1);
    });

    test('hidden for a non-Trustly country (CH)', async ({ page }) => {
        test.skip(process.env.PAYPAL_E2E !== '1', 'requires PAYPAL_E2E=1 with the PayPal module and sandbox');

        const db = new DatabaseHelper();
        const previous = await db.query(
            "SELECT OXACTIVE FROM oxcountry WHERE OXISOALPHA2 = 'CH' LIMIT 1",
        );
        const wasActive = previous[0]?.OXACTIVE ?? 0;
        await db.execute("UPDATE oxcountry SET OXACTIVE = 1 WHERE OXISOALPHA2 = 'CH'");

        try {
            const checkout = new O3CheckoutHelper(page);
            await checkout.setupAndGoto(PRODUCT_ID, guestAddress('trustly-ch', SWITZERLAND));

            await expect(
                checkout.paymentRadio(TRUSTLY_ID),
                'oscpaypal_trustly must not be offered outside its country set',
            ).toHaveCount(0);

            await expect(checkout.paymentRadio('oscpaypal')).toHaveCount(1);
        } finally {
            await db.execute("UPDATE oxcountry SET OXACTIVE = ? WHERE OXISOALPHA2 = 'CH'", [wasActive]);
            await db.close();
        }
    });
});
