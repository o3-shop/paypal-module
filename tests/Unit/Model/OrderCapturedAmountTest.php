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
final class OrderCapturedAmountTest extends UnitTestCase
{
    /**
     * @dataProvider capturedAmountProvider
     *
     * @param array<int, array{status: string, value: string, currency: string}> $captures
     */
    public function testHasPayPalCapturedAmountMismatch(
        array $captures,
        float $orderTotal,
        string $orderCurrency,
        bool $expected
    ): void {
        $order = oxNew(Order::class);
        $order->assign([
            'oxtotalordsum' => $orderTotal,
            'oxcurrency' => $orderCurrency,
        ]);

        $apiOrder = new PayPalApiOrder();
        $apiOrder->purchase_units = [
            (object)[
                'payments' => (object)[
                    'captures' => array_map(
                        static fn (array $capture): object => (object)[
                            'status' => $capture['status'],
                            'amount' => (object)[
                                'value' => $capture['value'],
                                'currency_code' => $capture['currency'],
                            ],
                        ],
                        $captures
                    ),
                ],
            ],
        ];

        $this->assertSame($expected, $order->hasPayPalCapturedAmountMismatch($apiOrder));
    }

    /**
     * @return array<string, array{0: array<int, array{status: string, value: string, currency: string}>, 1: float, 2: string, 3: bool}>
     */
    public static function capturedAmountProvider(): array
    {
        $completed = static fn (string $value, string $currency = 'EUR'): array => [
            'status' => 'COMPLETED',
            'value' => $value,
            'currency' => $currency,
        ];

        return [
            'exact match' => [[$completed('12.00')], 12.00, 'EUR', false],
            'rounding within tolerance' => [[$completed('12.004')], 12.00, 'EUR', false],
            'currency mismatch' => [[$completed('12.00', 'USD')], 12.00, 'EUR', true],
            'partial capture below total' => [[$completed('6.00')], 12.00, 'EUR', false],
            'two partial captures' => [[$completed('6.00'), $completed('6.00')], 12.00, 'EUR', false],
            'over-capture' => [[$completed('12.02')], 12.00, 'EUR', true],
            'pending is ignored' => [
                [['status' => 'PENDING', 'value' => '12.00', 'currency' => 'EUR']],
                12.00,
                'EUR',
                false,
            ],
            'discount/shipping/tax total matches' => [
                [$completed('12.00')],
                12.00,
                'EUR',
                false,
            ],
        ];
    }
}
