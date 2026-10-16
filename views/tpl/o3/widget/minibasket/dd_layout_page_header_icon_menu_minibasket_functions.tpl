[{if $oViewConf->showPayPalExpressInMiniBasket()}]
    [{oxhasrights ident="PAYWITHPAYPALEXPRESS"}]
        [{assign var="oConfig" value=$oViewConf->getConfig()}]
        [{assign var="PayPalSDKJS" value=$oConfig->getGlobalParameter("PayPalSDKJS")}]
        [{if !$PayPalSDKJS}]
            [{capture assign="PayPalSDKJS"}]
                [{include file="modules/osc/paypal/base_js.tpl" commitFlow=false}]
            [{/capture}]
            [{$oConfig->setGlobalParameter("PayPalSDKJS", $PayPalSDKJS)}]
        [{/if}]

        <div id="PayPalPayButtonNextCart1" class="paypal-button-container paypal-button-wrapper mt-2"></div>

        [{capture assign="paypalMinibasketInit"}]
            [{if !$aid}][{assign var="aid" value=""}][{/if}]
            [{assign var="sToken" value=$oViewConf->getSessionChallengeToken()}]
            [{assign var="sSelfLink" value=$oViewConf->getSslSelfLink()|replace:"&amp;":"&"}]
            [{if $oViewConf->isPayPalSandbox()}]
                [{assign var="sDebug" value="&XDEBUG_SESSION_START=1"}]
            [{else}]
                [{assign var="sDebug" value=""}]
            [{/if}]
            (function() {
                var rendered = false;
                function initPayPalMiniBasket() {
                    if (rendered) return;
                    if (typeof paypal === 'undefined' || typeof paypal.Buttons === 'undefined') return;
                    var btn = paypal.Buttons({
                        style: window.PayPalButtonStyle || {},
                        [{if $oViewConf->getCountryRestrictionForPayPalExpress()}]
                        onShippingChange: function(data, actions) {
                            if (!countryRestriction.includes(data.shipping_address.country_code)) {
                                return actions.reject();
                            }
                            return actions.resolve();
                        },
                        [{/if}]
                        createOrder: function(data, actions) {
                            window.PayPalExpressSession.started = true;
                            window.history.pushState(null, '');
                            return fetch('[{$sSelfLink|cat:"cl=oscpaypalproxy&fnc=createOrder&context=continue&aid="|cat:$aid|cat:"&stoken="|cat:$sToken|cat:$sDebug}]', {
                                method: 'post',
                                headers: { 'content-type': 'application/json' }
                            }).then(function(res) { return res.json(); }).then(function(data) { return data.id; });
                        },
                        onApprove: function(data, actions) {
                            var captureData = new FormData();
                            captureData.append('orderID', data.orderID);
                            return fetch('[{$sSelfLink|cat:"cl=oscpaypalproxy&fnc=approveOrder&context=continue&aid="|cat:$aid|cat:"&stoken="|cat:$sToken|cat:$sDebug}]', {
                                method: 'post',
                                body: captureData
                            }).then(function(res) { return res.json(); }).then(function(data) {
                                if (data.status == 'ERROR') { location.reload(); }
                                else if (data.id && data.status == 'APPROVED') { location.replace('[{$sSelfLink|cat:"cl=order"}]'); }
                            });
                        },
                        onCancel: function(data, actions) {
                            fetch('[{$sSelfLink|cat:"cl=oscpaypalproxy&fnc=cancelPayPalPayment"|cat:$sDebug}]').catch(function() {});
                        },
                        onError: function(data) {
                            fetch('[{$sSelfLink|cat:"cl=oscpaypalproxy&fnc=cancelPayPalPayment"|cat:$sDebug}]').catch(function() {});
                        }
                    });
                    if (btn.isEligible()) {
                        btn.render('#PayPalPayButtonNextCart1');
                        rendered = true;
                    }
                }
                var offcanvasEl = document.getElementById('offcanvas__basket');
                if (offcanvasEl) {
                    offcanvasEl.addEventListener('shown.bs.offcanvas', initPayPalMiniBasket);
                }
            })();
        [{/capture}]
        [{oxscript add=$paypalMinibasketInit}]
    [{/oxhasrights}]
[{/if}]
[{include file="modules/osc/paypal/paypalexpresshint.tpl" withBreak=true}]
