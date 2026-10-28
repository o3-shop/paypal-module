<?php

/**
 * Copyright © OXID eSales AG. All rights reserved.
 * See LICENSE file for license details.
 */

declare(strict_types=1);

namespace OxidSolutionCatalysts\PayPal\Tests\Unit\Core\ApplePay;

use OxidSolutionCatalysts\PayPal\Core\ApplePay\ApplePayDomainAssociation;
use PHPUnit\Framework\TestCase;

/**
 * @internal
 */
final class ApplePayDomainAssociationTest extends TestCase
{
    private string $shopBasePath;

    protected function setUp(): void
    {
        $this->shopBasePath = sys_get_temp_dir() . '/applepay-' . uniqid('', true) . '/';
        mkdir($this->shopBasePath, 0777, true);
    }

    protected function tearDown(): void
    {
        $this->removeDirectory($this->shopBasePath);
    }

    public function testInstallsFileIntoTheWellKnownDirectory(): void
    {
        $this->assertTrue(ApplePayDomainAssociation::ensureInstalled($this->shopBasePath));

        $target = $this->shopBasePath . '.well-known/apple-developer-merchantid-domain-association';
        $this->assertFileExists($target);
        $this->assertSame(
            file_get_contents(
                dirname(__DIR__, 4) . '/out/.well-known/apple-developer-merchantid-domain-association'
            ),
            file_get_contents($target)
        );
    }

    public function testDoesNotOverwriteAnExistingMerchantFile(): void
    {
        $directory = $this->shopBasePath . '.well-known';
        mkdir($directory, 0777, true);
        file_put_contents($directory . '/apple-developer-merchantid-domain-association', 'merchant specific');

        $this->assertTrue(ApplePayDomainAssociation::ensureInstalled($this->shopBasePath));
        $this->assertSame(
            'merchant specific',
            file_get_contents($directory . '/apple-developer-merchantid-domain-association')
        );
    }

    public function testIsIdempotent(): void
    {
        $this->assertTrue(ApplePayDomainAssociation::ensureInstalled($this->shopBasePath));
        $this->assertTrue(ApplePayDomainAssociation::ensureInstalled($this->shopBasePath));
    }

    private function removeDirectory(string $directory): void
    {
        if (!is_dir($directory)) {
            return;
        }

        foreach (scandir($directory) as $entry) {
            if ($entry === '.' || $entry === '..') {
                continue;
            }

            $path = $directory . '/' . $entry;
            if (is_dir($path)) {
                $this->removeDirectory($path);
            } else {
                @unlink($path);
            }
        }

        @rmdir($directory);
    }
}
