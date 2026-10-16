[{assign var="sSelfLink" value=$oViewConf->getSslSelfLink()|replace:"&amp;":"&"}]

<form action="[{$sSelfLink}]" method="post" class="order__delivery">
    <div class="d-none">
        [{$oViewConf->getHiddenSid()}]
        <input type="hidden" name="cl" value="payment">
        <input type="hidden" name="fnc" value="">
    </div>
    <h3 class="title-small">
        [{oxmultilang ident="SHIPPING_CARRIER"}]
        <button type="submit" class="btn btn-edit" title="[{oxmultilang ident="EDIT"}]">
            [{oxmultilang ident="EDIT"}]
        </button>
    </h3>
    [{assign var="oShipSet" value=$oView->getShipSet()}]
    [{$oShipSet->oxdeliveryset__oxtitle->value}]
</form>

<form action="[{$sSelfLink}]" method="post" class="order__payment" id="orderPayment">
    <div class="d-none">
        [{$oViewConf->getHiddenSid()}]
        <input type="hidden" name="cl" value="payment">
        <input type="hidden" name="fnc" value="">
    </div>
    <h3 class="title-small">
        [{oxmultilang ident="PAYMENT_METHOD"}]
        <a href="[{$sSelfLink|cat:"cl=payment"}]" title="[{oxmultilang ident="EDIT"}]">
            <button class="btn btn-edit" type="button">
                [{oxmultilang ident="EDIT"}]
            </button>
        </a>
    </h3>
    <div class="card-body">
        [{assign var="payment" value=$oView->getPayment()}]
        [{$payment->oxpayments__oxdesc->value}]
        [{if $oscpaypal_isVaultingPossible}]
            <br><br>
            <input type="checkbox" id="oscPayPalVaultPaymentCheckbox" disabled>
            <label for="oscPayPalVaultPaymentCheckbox">[{oxmultilang ident="OSC_PAYPAL_VAULTING_SAVE"}]</label>
        [{/if}]
    </div>
</form>
