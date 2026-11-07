#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 EDALVIX
# SPDX-License-Identifier: MIT
"""
Generate the Edalvix Cloud icon set in the style of edalvix.com.br:
blue gradient bodies (#0086fa -> #0051b9), deep blue panels (#0a3f94),
white rounded details, cyan accents (#3edcff) and a soft drop shadow.

Writes:
  theme/core/img/filetypes/*.svg  file type and folder icons (served by
                                  Nextcloud's /core/mimeicon through the theme)
  theme/core/img/edalvix/*.svg    icons used by the theme CSS

Usage: python3 branding/edalvix/tools/make-icons.py
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "theme" / "core" / "img"
FILETYPES = ROOT / "filetypes"
EXTRA = ROOT / "edalvix"

BLUE = ("#0086fa", "#0051b9", "#8fdcff")
RED = ("#ff6a52", "#c92f1f", "#ffc2b8")      # site "Firewall" accent family
GREEN = ("#22c995", "#087e62", "#a6f2d8")    # site "Backup" accent family
ORANGE = ("#ffa24a", "#e05d1c", "#ffd6ad")
CYAN = "#3edcff"
DEEP = "#0a3f94"
W = 'stroke="#fff" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" fill="none"'


def svg(body, defs="", size=80):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 80 80">'
        '<defs>'
        '<filter id="s" x="-20%" y="-20%" width="140%" height="150%">'
        '<feDropShadow dx="0" dy="4" stdDeviation="3" flood-color="#092454" flood-opacity=".18"/>'
        '</filter>'
        f'{defs}</defs><g filter="url(#s)">{body}</g></svg>\n'
    )


def grad(gid, c1, c2):
    return f'<linearGradient id="{gid}" x2=".8" y2="1"><stop stop-color="{c1}"/><stop offset="1" stop-color="{c2}"/></linearGradient>'


# ---------------------------------------------------------------- documents
def page(glyph, colors=BLUE):
    c1, c2, fold = colors
    body = (
        '<path d="M20 5h28l18 18v46a7 7 0 0 1-7 7H20a7 7 0 0 1-7-7V12a7 7 0 0 1 7-7Z" fill="url(#p)"/>'
        f'<path d="M48 5v12a6 6 0 0 0 6 6h12Z" fill="{fold}"/>'
        '<path d="M20 9h24" stroke="#fff" stroke-width="2" stroke-linecap="round" opacity=".28"/>'
        + glyph
    )
    return svg(body, grad("p", c1, c2))


GLYPHS = {
    "file": f'<path d="M24 40h26M24 49h32M24 58h18" {W} opacity=".9"/>',
    "application": f'<rect x="24" y="36" width="32" height="24" rx="4" {W}/><path d="M24 44h32" {W}/><circle cx="29" cy="40" r="1" fill="#fff"/>',
    "text": f'<path d="M24 38h22M24 47h32M24 56h28M24 65h16" {W} opacity=".95"/>',
    "text-code": f'<path d="M32 40l-9 9 9 9M48 40l9 9-9 9M43 36l-6 26" {W}/>',
    "x-office-document": f'<rect x="23" y="33" width="34" height="8" rx="3" fill="{CYAN}"/><path d="M24 50h32M24 58h26M24 66h18" {W}/>',
    "application-pdf": '<text x="40" y="58" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-weight="800" font-size="17" letter-spacing=".5" fill="#fff">PDF</text>',
    "x-office-spreadsheet": f'<rect x="22" y="34" width="36" height="30" rx="4" {W}/><path d="M22 44h36M22 54h36M34 34v30M46 34v30" stroke="#fff" stroke-width="3"/>',
    "x-office-presentation": f'<rect x="21" y="34" width="38" height="24" rx="4" {W}/><path d="M31 52v-6M40 52v-11M49 52v-8" {W}/><path d="M40 58v6" {W}/>',
    "x-office-drawing": f'<path d="M25 62l4-12 20-20 8 8-20 20Z" {W}/><path d="M45 34l8 8" {W}/>',
    "x-office-form": f'<rect x="24" y="35" width="8" height="8" rx="2" {W}/><path d="M38 39h18" {W}/><rect x="24" y="51" width="8" height="8" rx="2" fill="{CYAN}" stroke="#fff" stroke-width="3"/><path d="M38 55h18" {W}/>',
    "x-office-form-template": f'<rect x="24" y="35" width="32" height="10" rx="3" {W} stroke-dasharray="4 4"/><path d="M24 54h32M24 62h20" {W}/>',
    "image": f'<path d="M20 64l12-15 8 9 6-7 14 13Z" fill="#fff"/><circle cx="51" cy="38" r="5.5" fill="{CYAN}"/>',
    "video": f'<circle cx="40" cy="50" r="15" fill="{DEEP}" opacity=".35"/><path d="M35 41v18l14-9Z" fill="#fff"/>',
    "audio": f'<path d="M46 34v21" {W}/><circle cx="40" cy="57" r="6" fill="#fff"/><path d="M46 34l11-3v8l-11 3" fill="#fff"/><circle cx="54" cy="58" r="3" fill="{CYAN}"/>',
    "package-x-generic": f'<path d="M40 30v8M40 42v8M40 54v8" stroke="#fff" stroke-width="5" stroke-linecap="round"/><rect x="33" y="56" width="14" height="10" rx="3" fill="{CYAN}" stroke="#fff" stroke-width="2.5"/>',
    "text-calendar": f'<rect x="22" y="36" width="36" height="28" rx="4" {W}/><path d="M22 45h36M31 32v8M49 32v8" {W}/><rect x="44" y="51" width="7" height="7" rx="1.5" fill="{CYAN}"/>',
    "text-vcard": f'<circle cx="40" cy="44" r="7" fill="#fff"/><path d="M27 64c2-8 8-11 13-11s11 3 13 11Z" fill="#fff"/>',
    "font": '<text x="40" y="61" text-anchor="middle" font-family="Georgia, serif" font-weight="700" font-size="26" fill="#fff">Aa</text>',
    "link": f'<path d="M37 53l-4 4a7 7 0 0 1-10-10l6-6a7 7 0 0 1 10 0" {W}/><path d="M43 43l4-4a7 7 0 0 1 10 10l-6 6a7 7 0 0 1-10 0" {W}/>',
    "location": f'<path d="M40 66s-13-12-13-22a13 13 0 0 1 26 0c0 10-13 22-13 22Z" fill="#fff"/><circle cx="40" cy="44" r="5" fill="{CYAN}"/>',
    "mindmap": f'<path d="M40 50L27 38M40 50l13-12M40 50v13" {W}/><circle cx="40" cy="50" r="5" fill="{CYAN}" stroke="#fff" stroke-width="2"/><circle cx="26" cy="37" r="4" fill="#fff"/><circle cx="54" cy="37" r="4" fill="#fff"/><circle cx="40" cy="64" r="4" fill="#fff"/>',
    "whiteboard": f'<rect x="21" y="34" width="38" height="24" rx="3" {W}/><path d="M28 50c5-8 9 2 14-4s7 2 10-2" stroke="{CYAN}" stroke-width="3" stroke-linecap="round" fill="none"/><path d="M33 58l-4 7M47 58l4 7" {W}/>',
}

DOC_COLORS = {
    "application-pdf": RED,
    "x-office-spreadsheet": GREEN,
    "x-office-presentation": ORANGE,
}


# ------------------------------------------------------------------ folders
FOLDER_BACK = f'<path d="M15 10h16l7 7h28a7 7 0 0 1 7 7v38a7 7 0 0 1-7 7H15a7 7 0 0 1-7-7V17a7 7 0 0 1 7-7Z" fill="{DEEP}"/>'
FOLDER_FRONT = (
    '<rect x="5" y="26" width="70" height="44" rx="7" fill="url(#f)"/>'
    '<path d="M12 32h56" stroke="#fff" stroke-width="2" stroke-linecap="round" opacity=".3"/>'
)


def badge(glyph):
    return f'<circle cx="60" cy="58" r="14" fill="{CYAN}" stroke="#fff" stroke-width="3.5"/>{glyph}'


BADGE = 'stroke="#fff" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round" fill="none"'
FOLDERS = {
    "folder": "",
    "folder-shared": badge(f'<circle cx="55" cy="58" r="2.6" fill="#fff"/><circle cx="65" cy="52.5" r="2.6" fill="#fff"/><circle cx="65" cy="63.5" r="2.6" fill="#fff"/><path d="M55 58l10-5.5M55 58l10 5.5" stroke="#fff" stroke-width="2"/>'),
    "folder-public": badge(f'<path d="M57 61l-1.5 1.5a3.5 3.5 0 0 1-5-5l3-3a3.5 3.5 0 0 1 5 0M63 55l1.5-1.5a3.5 3.5 0 0 1 5 5l-3 3a3.5 3.5 0 0 1-5 0" {BADGE}/>'),
    "folder-external": badge(f'<path d="M55 63l10-10M58 53h7v7" {BADGE}/>'),
    "folder-encrypted": badge(f'<rect x="54" y="57" width="12" height="9" rx="2" fill="#fff"/><path d="M56.5 57v-3a3.5 3.5 0 0 1 7 0v3" stroke="#fff" stroke-width="2.6" stroke-linecap="round" fill="none"/>'),
    "folder-starred": badge('<path d="M60 49.5l2.6 5.3 5.8.8-4.2 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8-4.2-4.1 5.8-.8Z" fill="#fff"/>'),
    "folder-drag-accept": badge(f'<path d="M60 52v12M54 58h12" {BADGE}/>'),
}


def folder(extra):
    return svg(FOLDER_BACK + FOLDER_FRONT + extra, grad("f", BLUE[0], BLUE[1]))


# ----------------------------------------------------------- theme extras
def share_icon():
    # "add person" for the share action, in the same family
    body = (
        '<circle cx="34" cy="28" r="12" fill="url(#g)"/>'
        '<path d="M12 66c2-14 11-20 22-20s20 6 22 20Z" fill="url(#g)"/>'
        f'<circle cx="60" cy="56" r="12" fill="{CYAN}" stroke="#fff" stroke-width="3.5"/>'
        f'<path d="M60 50v12M54 56h12" {BADGE}/>'
    )
    return svg(body, grad("g", BLUE[0], BLUE[1]))


def main():
    FILETYPES.mkdir(parents=True, exist_ok=True)
    EXTRA.mkdir(parents=True, exist_ok=True)
    for name, glyph in GLYPHS.items():
        (FILETYPES / f"{name}.svg").write_text(page(glyph, DOC_COLORS.get(name, BLUE)))
    for name, extra in FOLDERS.items():
        (FILETYPES / f"{name}.svg").write_text(folder(extra))
    (EXTRA / "folder.svg").write_text(folder(""))
    (EXTRA / "share.svg").write_text(share_icon())
    print(f"{len(GLYPHS) + len(FOLDERS)} file type icons in {FILETYPES}")


if __name__ == "__main__":
    main()
