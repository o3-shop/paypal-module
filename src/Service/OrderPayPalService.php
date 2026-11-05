<?php

namespace OxidSolutionCatalysts\PayPal\Service;

use OxidEsales\Eshop\Core\Request;

class OrderPayPalService
{
    private Request $request;
    private Payment $paymentService;

    public function __construct(Request $request, Payment $paymentService)
    {
        $this->paymentService = $paymentService;
        $this->request = $request;
    }

    public function cancelPayPalSession(string $errorcode = null): string
    {
        //TODO: we get the PayPal order id retuned in token parameter, can be used for paranoia checks
        //(string) Registry::getRequest()->getRequestParameter('token')
        $requestErrorcode = $this->getStringRequestParameter('errorcode');

        $cancelBlocked = $this->paymentService->removeTemporaryOrder();

        if ($cancelBlocked) {
            // PENDING/APPROVED/COMPLETED at PayPal: do not invite a retry that
            // could pay a second order. The webhook settles the open payment.
            return 'thankyou';
        }

        $goNext = 'payment';
        if ($errorcode || $requestErrorcode) {
            $goNext = 'payment?payerror=2';
        }

        return $goNext;
    }

    private function getStringRequestParameter(string $key): ?string
    {
        $value = $this->request->getRequestParameter($key);

        return is_string($value) ? $value : null;
    }
}
