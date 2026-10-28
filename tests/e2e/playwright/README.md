# Playwright E2E Testing
## How to Install
1. Navigate to the folder. `tests/e2e/playwright`
2. 
``` bash
   cp .env.dist .env
    # Edit .env to set your environment variables
   make install
```
### Run tests in Headless Mode
``` bash
   make test
```
### View Tests in Realtime (Headed Mode)
Run tests with a visible browser:
``` bash
   make play
```

## Trustly (PayPal uAPM) tests
The Trustly visibility and failed-payment specs were moved here from shop-ce.
They need an O3-Shop with the PayPal module, demo data and a PayPal sandbox.
Set these values in `.env`:

``` dotenv
PAYPAL_E2E=1
BASE_URL=https://<oxid-shop-hostname>
TRUSTLY_PRODUCT_ID=<buyable demo product id>
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASS=supersecret
DB_NAME=o3shop
```

The CH visibility case temporarily activates Switzerland in `oxcountry` and
restores the previous value in a `finally` block. Run the two specs with:

``` bash
npx playwright test tests/e2e/Trustly*.spec.js
```

## How to Run and View Tests on a URL
To test and see a hosted environment, ensure the in is set to: `BASE_URL``.env`
``` dotenv
BASE_URL=https://<oxid-shop-hostname>
```

Navigate to the **Playwright Web Interface** (for trace, logs):
``` bash
http://127.0.0.1:4040
```



## How to run with ngrok
To run tests with ngrok, you need to set up ngrok to tunnel your local server. Follow these steps:
1. Install ngrok if you haven't already.
``` bash
    curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list && \
    sudo apt-get update && sudo apt-get install ngrok
``` 
2. Run ngrok with your custom domain:
``` bash
      ngrok config add-authtoken <get_your_own_token_from_ngrok>
      ngrok http --hostname=<get_your_own_domain_from_ngrok> 80 > /dev/null 2>&1 &
```

### Test your ngrok connection
``` bash
          curl -I https://<get_your_own_domain_from_ngrok>
          curl -v https://<get_your_own_domain_from_ngrok>
          curl -o /dev/null -s -w "%{http_code}\n" https://<get_your_own_domain_from_ngrok>
```         

### Update config.inc.php
Add ngrok domain to your `Oxid's config.inc.php` file.
