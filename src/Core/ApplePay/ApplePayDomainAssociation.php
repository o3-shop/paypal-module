<?php

/**
 * Copyright © OXID eSales AG. All rights reserved.
 * See LICENSE file for license details.
 */

declare(strict_types=1);

namespace OxidSolutionCatalysts\PayPal\Core\ApplePay;

/**
 * Apple Pay requires the domain association file at
 * /.well-known/apple-developer-merchantid-domain-association.
 *
 * The module ships a copy and installs it into the shop's docroot when the
 * shop has none yet. An existing file is never overwritten: it is signed for
 * the merchant's domain and may have been provided by the merchant. The core
 * file remains as a fallback until every shop runs a module version that can
 * provide it.
 */
final class ApplePayDomainAssociation
{
    private const RELATIVE_SOURCE = '/out/.well-known/apple-developer-merchantid-domain-association';
    private const RELATIVE_TARGET = '/.well-known/apple-developer-merchantid-domain-association';

    public static function ensureInstalled(string $shopBasePath): bool
    {
        $source = dirname(__DIR__, 3) . self::RELATIVE_SOURCE;
        $target = rtrim($shopBasePath, '/\\') . self::RELATIVE_TARGET;

        if (!is_file($source)) {
            return false;
        }

        if (is_file($target)) {
            return true;
        }

        $directory = dirname($target);
        if (!is_dir($directory) && !@mkdir($directory, 0755, true) && !is_dir($directory)) {
            return false;
        }

        return @copy($source, $target);
    }
}
