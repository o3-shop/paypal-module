<?php

/**
 * Copyright © OXID eSales AG. All rights reserved.
 * See LICENSE file for license details.
 */

declare(strict_types=1);

namespace OxidSolutionCatalysts\PayPal\Tests\Unit\Model;

use OxidEsales\TestingLibrary\UnitTestCase;
use OxidSolutionCatalysts\PayPal\Model\Order;
use OxidSolutionCatalysts\PayPalApi\Model\Orders\Order as PayPalApiOrder;

// The module's unified-namespace generator creates this alias in the module
// test environment; the shop test bootstrap does not. Define it only when the
// generated alias is absent.
if (!class_exists('OxidSolutionCatalysts\PayPal\Model\Order_parent')) {
    class_alias(
        \OxidEsales\Eshop\Application\Model\Order::class,
        'OxidSolutionCatalysts\PayPal\Model\Order_parent'
    );
}

/**
 * @internal
 */
final class OrderPaymentStatusTest extends UnitTestCase
{
    /**
     * @dataProvider paymentStatusProvider
     */
    public function testIsPayPalPaymentStillOpen(
        string $orderStatus,
        ?string $captureStatus,
        bool $expected
    ): void {
        $apiOrder = new PayPalApiOrder();
        $apiOrder->status = $orderStatus;
        $apiOrder->purchase_units = $captureStatus === null
            ? []
            : [
                (object)[
                    'payments' => (object)[
                        'captures' => [(object)['status' => $captureStatus]],
                    ],
                ],
            ];

        $order = oxNew(Order::class);

        $this->assertSame($expected, $order->isPayPalPaymentStillOpen($apiOrder));
    }

    /**
     * @return array<string, array{0: string, 1: string|null, 2: bool}>
     */
    public static function paymentStatusProvider(): array
    {
        return [
            'completed capture keeps the payment open' => ['COMPLETED', 'COMPLETED', true],
            'pending capture keeps the payment open' => ['COMPLETED', 'PENDING', true],
            'denied capture is not a live payment' => ['COMPLETED', 'DENIED', false],
            'failed capture is not a live payment' => ['COMPLETED', 'FAILED', false],
            'approved order keeps the payment open' => ['APPROVED', null, true],
            'created order is not open' => ['CREATED', null, false],
            'payer action required is not open' => ['PAYER_ACTION_REQUIRED', null, false],
        ];
    }
}
