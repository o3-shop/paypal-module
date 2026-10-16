[{if $vaultedPaymentSources}]
    <div class="mb-3">
        <h3 class="title-small">[{oxmultilang ident="OSC_PAYPAL_VAULTING_VAULTED_PAYMENTS"}]</h3>
        [{foreach from=$vaultedPaymentSources item=vaultedPayment key="paymentTokenId"}]
            <div class="mb-2 p-2 border rounded">
                <dl class="mb-0">
                    <dt>
                        <input type="radio" name="vaulting_paymentsource" class="vaulting_paymentsource"
                               id="paymenttoken_[{$vaultedPayment.id}]"
                               data-token-id="[{$vaultedPayment.id}]"
                               data-paymenttype="[{$vaultedPayment.type}]"
                        >
                        <label for="paymenttoken_[{$vaultedPayment.id}]">[{$vaultedPayment.label}]</label>
                    </dt>
                </dl>
            </div>
        [{/foreach}]
        <div class="text-end mt-2">
            <button type="submit" name="userform"
                    class="btn btn-primary"
                    id="paypalVaultCheckoutButton"
                    disabled
            >
                [{oxmultilang ident="OSC_PAYPAL_CONTINUE_TO_NEXT_STEP"}]
            </button>
        </div>
    </div>
[{/if}]

[{if 'oscpaypal_express'|array_key_exists:$oView->getPaymentList() && $oViewConf->isPayPalExpressSessionActive()}]
    [{assign var="config" value=$oViewConf->getPayPalCheckoutConfig()}]
    <div class="mb-3">
        <h3 class="title-small">[{oxmultilang ident="OSC_PAYPAL_PAY_EXPRESS"}]</h3>
        <div class="row">
            <div class="col-12 col-md-6">
                [{oxmultilang ident="OSC_PAYPAL_PAY_PROCESSED"}]
            </div>
            <div class="col-12 col-md-6 text-end">
                <a class="btn btn-outline-dark" href="[{$oViewConf->getCancelPayPalPaymentUrl()}]">[{oxmultilang ident="OSC_PAYPAL_PAY_UNLINK"}]</a>
            </div>
        </div>
        [{capture name="hide_payment"}]
            [{literal}]
                $(function () {
                    $('#payment > .payment__payments:first .payment__navi').hide();
                });
            [{/literal}]
        [{/capture}]
        [{oxscript add=$smarty.capture.hide_payment}]
    </div>
[{/if}]
