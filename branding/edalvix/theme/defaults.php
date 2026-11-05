<?php

/**
 * Edalvix Cloud - Nextcloud theme
 *
 * Installed at <nextcloud>/themes/edalvix and activated with
 *   occ config:system:set theme --value=edalvix
 *
 * These are the defaults; anything configured in the Theming app
 * (Administration settings > Theming) takes precedence.
 *
 * SPDX-FileCopyrightText: 2026 EDALVIX
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

class OC_Theme {
	private const NAME = 'Edalvix Cloud';
	private const ENTITY = 'EDALVIX';
	private const BASE_URL = 'https://edalvix.com.br';
	private const SLOGAN = 'Seus arquivos sempre com você';
	private const COLOR_PRIMARY = '#0068ce';
	private const COLOR_BACKGROUND = '#071d33';
	private const CLIENT_DOWNLOAD_URL = 'https://edalvix.com.br/cloud/download';

	public function getBaseUrl(): string {
		return self::BASE_URL;
	}

	public function getDocBaseUrl(): string {
		return 'https://docs.nextcloud.com';
	}

	public function getTitle(): string {
		return self::NAME;
	}

	public function getName(): string {
		return self::NAME;
	}

	public function getHTMLName(): string {
		return '<strong>EDALVIX</strong> Cloud';
	}

	public function getEntity(): string {
		return self::ENTITY;
	}

	public function getSlogan(?string $lang = null): string {
		return self::SLOGAN;
	}

	public function getShortFooter(): string {
		// Product first; the EDALVIX company brand is a secondary signature.
		return self::NAME . ' – ' . self::SLOGAN
			. ' · um produto <a href="' . self::BASE_URL . '" target="_blank" rel="noreferrer noopener">'
			. self::ENTITY . '</a>';
	}

	public function getLongFooter(): string {
		return $this->getShortFooter()
			. '<br/>Tecnologia que conecta. Estrutura que sustenta.';
	}

	public function buildDocLinkToKey($key): string {
		return $this->getDocBaseUrl() . '/server/latest/go.php?to=' . $key;
	}

	public function getColorPrimary(): string {
		return self::COLOR_PRIMARY;
	}

	public function getColorBackground(): string {
		return self::COLOR_BACKGROUND;
	}

	public function getSyncClientUrl(): string {
		return self::CLIENT_DOWNLOAD_URL;
	}

	public function getiOSClientUrl(): string {
		return self::CLIENT_DOWNLOAD_URL;
	}

	public function getAndroidClientUrl(): string {
		return self::CLIENT_DOWNLOAD_URL;
	}

	public function getScssVariables(): array {
		return [
			'color-primary' => self::COLOR_PRIMARY,
		];
	}
}
