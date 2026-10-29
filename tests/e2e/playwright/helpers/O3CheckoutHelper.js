// Checkout helper for the O3-Shop storefront (Wave theme).
//
// The Trustly specs were moved here from shop-ce. They intentionally drive the
// real storefront as a guest so they can run against any O3-Shop with the
// PayPal module, not only the shop's internal acceptance stack.

const DEFAULT_COUNTRY_ID = 'a7c40f631fc920687.20179984'; // Germany

export class O3CheckoutHelper {
    constructor(page) {
        if (!page) {
            throw new Error('Invalid or undefined "page" provided to O3CheckoutHelper.');
        }
        this.page = page;
    }

    /**
     * Drive the checkout as a guest from a fresh session to the payment step.
     *
     * @param {string} productId
     * @param {{email: string, firstName: string, lastName: string, street: string, streetNo: string, zip: string, city: string, countryId?: string}} address
     */
    async setupAndGoto(productId, address) {
        const { page } = this;

        await page.request.post(`/index.php?cl=start&fnc=tobasket&aid=${productId}&am=1`);
        await page.goto('/index.php?cl=user', { waitUntil: 'domcontentloaded' });

        // option=1 is the passwordless guest checkout in o3-theme.
        await page
            .locator('form input[name="option"][value="1"]')
            .first()
            .evaluate((input) => input.form?.submit());
        await page.waitForLoadState('domcontentloaded');

        await page.locator('input[name="lgn_usr"]').first().fill(address.email);
        await page.locator('input[name="invadr[oxuser__oxfname]"]').fill(address.firstName);
        await page.locator('input[name="invadr[oxuser__oxlname]"]').fill(address.lastName);
        await page.locator('input[name="invadr[oxuser__oxstreet]"]').fill(address.street);
        await page.locator('input[name="invadr[oxuser__oxstreetnr]"]').fill(address.streetNo);
        await page.locator('input[name="invadr[oxuser__oxzip]"]').fill(address.zip);
        await page.locator('input[name="invadr[oxuser__oxcity]"]').fill(address.city);
        await page
            .locator('select[name="invadr[oxuser__oxcountryid]"]')
            .selectOption(address.countryId ?? DEFAULT_COUNTRY_ID);

        await page
            .locator('form')
            .filter({ has: page.locator('input[name="invadr[oxuser__oxfname]"]') })
            .first()
            .evaluate((form) => form.submit());
        await page.waitForLoadState('networkidle', { timeout: 15000 });

        if (!/cl=payment|\/zahlart\b/.test(page.url())) {
            await page.goto('/index.php?cl=payment', { waitUntil: 'domcontentloaded' });
        }
        if (!/cl=payment|\/zahlart\b/.test(page.url())) {
            const title = await page.title().catch(() => '<unavailable>');
            const errors = await page.locator('.alert-danger').allTextContents().catch(() => []);
            throw new Error(
                `setupAndGoto: expected the payment step, got url=${page.url()} title=${title} errors=${JSON.stringify(errors)}`,
            );
        }
    }

    paymentRadio(paymentId) {
        return this.page.locator(`input[type="radio"][name="paymentid"][value="${paymentId}"]`);
    }

    async selectPayment(paymentId) {
        await this.paymentRadio(paymentId).check();
    }

    async continueToOrder() {
        await Promise.all([
            this.page.waitForLoadState('domcontentloaded'),
            this.page.locator('button[name="userform"]').click(),
        ]);
    }

    async orderNow() {
        await Promise.all([
            this.page.waitForLoadState('domcontentloaded'),
            this.page.locator('.order__navi button[type=submit]').click(),
        ]);
    }
}
