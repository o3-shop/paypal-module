<?php

/**
 * Copyright © OXID eSales AG. All rights reserved.
 * See LICENSE file for license details.
 */

declare(strict_types=1);

namespace OxidSolutionCatalysts\PayPal\Tests\Unit\Service;

use OxidEsales\Eshop\Application\Model\Basket;
use OxidEsales\Eshop\Core\Registry;
use OxidEsales\TestingLibrary\UnitTestCase;
use OxidSolutionCatalysts\PayPal\Core\PatchRequestFactory;
use OxidSolutionCatalysts\PayPal\Core\PayPalSession;
use OxidSolutionCatalysts\PayPal\Core\ServiceFactory;
use OxidSolutionCatalysts\PayPal\Model\Order;
use OxidSolutionCatalysts\PayPal\Service\Factory\OrderRequestFactory;
use OxidSolutionCatalysts\PayPal\Service\ModuleSettings;
use OxidSolutionCatalysts\PayPal\Service\OrderProcessTrackingService;
use OxidSolutionCatalysts\PayPal\Service\OrderRepository;
use OxidSolutionCatalysts\PayPal\Service\Payment;
use OxidSolutionCatalysts\PayPal\Service\SCAValidatorInterface;
use PHPUnit\Framework\MockObject\MockObject;
use Psr\Log\LoggerInterface;

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
final class PaymentRemoveTemporaryOrderTest extends UnitTestCase
{
    private const SHOP_ORDER_ID = 'dead-shop-order';

    public function testDeadCaptureClearsSessionAndBasketAndStornosOrder(): void
    {
        $order = $this->createBlockedOrder(false);
        $order->expects($this->once())->method('markOrderPaymentFailed');
        $order->expects($this->once())->method('cancelOrder');

        $basket = $this->prepareSession();

        $this->assertFalse($this->createPaymentService($order)->removeTemporaryOrder(self::SHOP_ORDER_ID));
        $this->assertNull($basket->getOrderId());
        $this->assertNull(PayPalSession::getCheckoutOrderId());
        $this->assertNull(Registry::getSession()->getVariable('sess_challenge'));
    }

    public function testOpenPaymentKeepsOrderAndChallenge(): void
    {
        $order = $this->createBlockedOrder(true);
        $order->expects($this->never())->method('markOrderPaymentFailed');
        $order->expects($this->never())->method('cancelOrder');

        $basket = $this->prepareSession();

        $this->assertTrue($this->createPaymentService($order)->removeTemporaryOrder(self::SHOP_ORDER_ID));
        $this->assertNull($basket->getOrderId());
        $this->assertNull(PayPalSession::getCheckoutOrderId());
        $this->assertSame(self::SHOP_ORDER_ID, Registry::getSession()->getVariable('sess_challenge'));
    }

    /**
     * A shop order whose cancel was refused (PayPal checkout order COMPLETED).
     *
     * @return MockObject|Order
     */
    private function createBlockedOrder(bool $paymentStillOpen): MockObject
    {
        $order = $this->getMockBuilder(Order::class)
            ->disableOriginalConstructor()
            ->onlyMethods([
                'cancelPayPalOrder',
                'getFieldData',
                'isPayPalPaymentStillOpen',
                'markOrderPaymentFailed',
                'cancelOrder',
                'getId',
            ])
            ->getMock();
        $order->method('cancelPayPalOrder')->willReturn(false);
        $order->method('getFieldData')->willReturn('0');
        $order->method('isPayPalPaymentStillOpen')->willReturn($paymentStillOpen);
        $order->method('getId')->willReturn(self::SHOP_ORDER_ID);

        return $order;
    }

    private function prepareSession(): Basket
    {
        $session = Registry::getSession();
        $basket = oxNew(Basket::class);
        $basket->setOrderId(self::SHOP_ORDER_ID);
        $session->setBasket($basket);
        $session->setVariable('sess_challenge', self::SHOP_ORDER_ID);
        PayPalSession::storePayPalOrderId('dead-paypal-order');

        return $basket;
    }

    /**
     * @param MockObject|Order $order
     * @return MockObject|Payment
     */
    private function createPaymentService(MockObject $order): MockObject
    {
        $payment = $this->getMockBuilder(Payment::class)
            ->setConstructorArgs([
                Registry::getSession(),
                $this->createMock(OrderRepository::class),
                $this->createMock(SCAValidatorInterface::class),
                $this->createMock(ModuleSettings::class),
                $this->createMock(LoggerInterface::class),
                $this->createMock(OrderProcessTrackingService::class),
                $this->createMock(ServiceFactory::class),
                $this->createMock(PatchRequestFactory::class),
                $this->createMock(OrderRequestFactory::class),
            ])
            ->onlyMethods(['getTemporaryOrder'])
            ->getMock();
        $payment->method('getTemporaryOrder')->willReturn($order);

        return $payment;
    }
}
