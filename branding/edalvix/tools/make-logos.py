#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 EDALVIX
# SPDX-License-Identifier: MIT
"""
Edalvix Cloud logos: the Cloud icon, the official EDALVIX wordmark (the
geometric letters of edalvix.com.br, not a font) and "Cloud" in bold, as in
the product cards of the site.

Writes the server theme logos and, with --desktop, the desktop client
wizard logo (SVG + PNG renders need a browser: see --png).

Usage:
  python3 branding/edalvix/tools/make-logos.py [--desktop /path/to/desktopnextcloud]
"""
import argparse
from pathlib import Path

HERE = Path(__file__).resolve().parent
BRAND = HERE.parent

# Official wordmark, 897 x 90 units (from edalvix.com.br assets)
WORDMARK = '''<path d="M14 0 H107 V19 H26 Q22 19 22 23 V35 H96 V53 H22 V66 Q22 71 27 71 H107 V90 H14 Q0 90 0 76 V14 Q0 0 14 0 Z" fill-rule="evenodd" transform="translate(0,0)" /><path d="M0 0 H63 C100 0 123 18 123 45 C123 73 101 90 63 90 H0 Z M24 20 V70 H62 C85 70 98 62 98 45 C98 28 85 20 62 20 Z" fill-rule="evenodd" transform="translate(129,0)" /><path d="M0 90 54 9 Q60 0 66 0 H72 Q79 0 84 9 L138 90 H110 L69 27 L28 90 Z" fill-rule="evenodd" transform="translate(273,0)" /><path d="M0 0 H24 V64 Q24 71 32 71 H109 V90 H19 Q0 90 0 73 Z" fill-rule="evenodd" transform="translate(432,0)" /><path d="M0 0 H29 L67 63 L105 0 H134 L83 82 Q78 90 71 90 H63 Q57 90 51 82 Z" fill-rule="evenodd" transform="translate(561,0)" /><path d="M0 0 H24 V90 H0 Z" fill-rule="evenodd" transform="translate(716,0)" /><path d="M0 0 H31 L66 33 L102 0 H134 L83 45 L134 90 H102 L66 57 L30 90 H0 L49 45 Z" fill-rule="evenodd" transform="translate(763,0)" />'''
WM_W, WM_H = 897.0, 90.0

CYL_DEFS = '<linearGradient id="ecb" x2=".8" y2="1"><stop stop-color="#0086fa"/><stop offset="1" stop-color="#0051b9"/></linearGradient>'
CYL = ('<path fill="url(#ecb)" d="M9 19h62v42c0 9-14 16-31 16S9 70 9 61Z"/>'
       '<ellipse cx="40" cy="19" rx="31" ry="15" fill="#087df1"/>'
       '<path d="M9 20c0 9 14 16 31 16s31-7 31-16M9 40c0 9 14 16 31 16s31-7 31-16" fill="none" stroke="#fff" stroke-width="4"/>')
FONT = 'font-family="Arial, Helvetica, sans-serif" font-weight="700"'

# word colour, "Cloud" colour
ON_DARK = ("#ffffff", "#6bb4ff")
ON_LIGHT = ("#061430", "#0877ff")


def wordmark(x, y, height, colour):
    s = height / WM_H
    return f'<g fill="{colour}" transform="translate({x:g},{y:g}) scale({s:.5f})">{WORDMARK}</g>'


def svg(w, h, body):
    return (f'<?xml version="1.0" encoding="UTF-8"?>\n'
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{w:g}" height="{h:g}" viewBox="0 0 {w:g} {h:g}">'
            f'<defs>{CYL_DEFS}</defs>{body}</svg>\n')


def stacked(colours):
    """Login / theming logo: icon left, EDALVIX over Cloud."""
    word, cloud = colours
    wm_h = 25
    wm_w = WM_W * wm_h / WM_H
    body = (f'<g transform="translate(0,8) scale(1.18)">{CYL}</g>'
            + wordmark(112, 18, wm_h, word)
            + f'<text x="109" y="95" {FONT} font-size="48" letter-spacing="-1.2" fill="{cloud}">Cloud</text>')
    return svg(112 + wm_w + 4, 110, body)


def inline(colours):
    """Header: icon, EDALVIX and Cloud on one line."""
    word, cloud = colours
    wm_h = 14
    wm_w = WM_W * wm_h / WM_H
    x_cloud = 50 + wm_w + 8
    body = (f'<g transform="translate(0,4) scale(0.5)">{CYL}</g>'
            + wordmark(50, 17, wm_h, word)
            + f'<text x="{x_cloud:g}" y="31" {FONT} font-size="20" letter-spacing="-0.4" fill="{cloud}">Cloud</text>')
    return svg(x_cloud + 62, 48, body)


def centred(colours):
    """Desktop wizard (at most 2:1): icon on top, EDALVIX, then Cloud."""
    word, cloud = colours
    wm_h = 22
    wm_w = WM_W * wm_h / WM_H
    w = wm_w + 8
    body = (f'<g transform="translate({w / 2 - 36:g},0) scale(0.9)">{CYL}</g>'
            + wordmark(4, 82, wm_h, word)
            + f'<text x="{w / 2:g}" y="148" text-anchor="middle" {FONT} font-size="40" letter-spacing="-1" fill="{cloud}">Cloud</text>')
    return svg(w, 158, body)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--desktop", type=Path, help="desktopnextcloud checkout to update the wizard logo in")
    args = ap.parse_args()

    assets = BRAND / "assets"
    img = BRAND / "theme" / "core" / "img"
    (assets / "logo.svg").write_text(stacked(ON_DARK))          # login (hero background)
    (assets / "logo-dark.svg").write_text(stacked(ON_LIGHT))    # for light backgrounds
    (img / "logo" / "logo.svg").write_text(stacked(ON_DARK))
    (img / "edalvix" / "header-logo-light.svg").write_text(inline(ON_LIGHT))
    (img / "edalvix" / "header-logo-dark.svg").write_text(inline(ON_DARK))
    print("server logos written")
    if args.desktop:
        (args.desktop / "theme" / "colored" / "wizard_logo.svg").write_text(centred(ON_LIGHT))
        print("desktop wizard_logo.svg written (render the PNGs from it)")


if __name__ == "__main__":
    main()
