<?php

/**
 * Copyright © OXID eSales AG. All rights reserved.
 * See LICENSE file for license details.
 */

declare(strict_types=1);

namespace OxidSolutionCatalysts\PayPal\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;
use OxidSolutionCatalysts\PayPal\Core\ApplePay\ApplePayDomainAssociation;

final class Version20261028120000 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Install the Apple Pay domain association file when the shop has none.';
    }

    public function up(Schema $schema): void
    {
        if (function_exists('getShopBasePath')) {
            ApplePayDomainAssociation::ensureInstalled(getShopBasePath());
        }
    }

    public function down(Schema $schema): void
    {
    }
}
