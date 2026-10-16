[{$smarty.block.parent}]
[{if $oViewConf->isO3CompatibleTheme()
    && $oView->getClassName() == 'details'
    && $oViewConf->enablePayPalBanners()
    && $oViewConf->getPayPalClientId()
    && $oViewConf->showPayPalCheckoutBannerOnProductDetailsPage()}]
<div id="paypal-installment-banner-container"></div>
[{/if}]
