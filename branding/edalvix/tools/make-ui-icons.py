#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 EDALVIX
# SPDX-License-Identifier: MIT
"""
Restyle every Nextcloud interface icon in the edalvix.com.br style: the
original shape (so users still recognise it) filled with the site's blue
gradient (#0a8cff -> #0051b9) and a soft shadow, like the site's icons.

Three kinds of icons exist in Nextcloud 35 and each is handled differently:

1. Vue "material design" icons with a class (e.g. .upload-icon) and
2. Vue icons without a class (.icon-vue, matched by their path data):
   listed in ui-icons.json (made with an inventory of the real screens),
   drawn to theme/core/img/edalvix/ui/*.svg and switched by
   theme/core/css/icons.css.
3. Icon files (core/img/actions, apps/*/img): overridden through the theme
   folder (themes/edalvix/core/img/..., themes/edalvix/apps/<app>/img/...),
   which Nextcloud looks up first. Needs a Nextcloud tree to read from.

Usage:
  python3 branding/edalvix/tools/make-ui-icons.py [--nextcloud /path/to/nextcloud]
"""
import argparse
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

HERE = Path(__file__).resolve().parent
THEME = HERE.parent / "theme"
UI_DIR = THEME / "core" / "img" / "edalvix" / "ui"
CSS = THEME / "core" / "css" / "icons.css"
SVG_NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG_NS)

C1, C2 = "#0a8cff", "#0051b9"

# Apps whose icon files users can see (the ones kept by the lockdown)
APPS = [
    "files", "files_sharing", "files_trashbin", "files_versions", "files_lock",
    "viewer", "files_pdfviewer", "text", "theming", "notifications", "settings",
    "password_policy", "twofactor_totp", "twofactor_backupcodes", "dav",
    "workflowengine", "serverinfo", "logreader", "appstore", "provisioning_api",
]

# Never restyled: spinners, and icons drawn on top of a primary (gradient) button
SKIP_NAMES = {"loading-icon"}
EXCLUDE = ".button-vue--vue-primary, .button-vue--primary, button.primary, .checkbox-radio-switch--checked .checkbox-radio-switch__icon"


def defs(x, y, w, h):
    return (
        f'<defs><linearGradient id="eg" gradientUnits="userSpaceOnUse" x1="{x:g}" y1="{y:g}" '
        f'x2="{x + w * .8:g}" y2="{y + h:g}"><stop stop-color="{C1}"/><stop offset="1" stop-color="{C2}"/>'
        f'</linearGradient><filter id="es" x="-20%" y="-20%" width="140%" height="150%">'
        f'<feDropShadow dx="0" dy="{h * .035:g}" stdDeviation="{h * .03:g}" flood-color="#092454" flood-opacity=".22"/>'
        f'</filter></defs>'
    )


def glyph(shapes, viewbox="0 0 24 24"):
    x, y, w, h = (float(v) for v in viewbox.split())
    return (
        f'<svg xmlns="{SVG_NS}" viewBox="{viewbox}" width="{w:g}" height="{h:g}">'
        f'{defs(x, y, w, h)}<g fill="url(#eg)" filter="url(#es)">{shapes}</g></svg>\n'
    )


def svg_shapes(svg_markup):
    """Paths/circles/rects of an inline svg, without fills or helper rects."""
    root = ET.fromstring(svg_markup if "xmlns" in svg_markup else svg_markup.replace("<svg", f'<svg xmlns="{SVG_NS}"', 1))
    vb = root.get("viewBox", "0 0 24 24")
    out = []
    for el in root.iter():
        tag = el.tag.split("}")[-1]
        if tag not in ("path", "circle", "rect", "ellipse", "polygon"):
            continue
        d = el.get("d", "")
        if re.fullmatch(r"\s*M0 0h24v24H0[zZ]?\s*", d) or el.get("fill") == "none":
            continue  # bounding helper
        attrs = " ".join(f'{k}="{v}"' for k, v in el.attrib.items()
                         if k in ("d", "cx", "cy", "r", "rx", "ry", "x", "y", "width", "height", "points", "fill-rule", "clip-rule", "transform"))
        out.append(f"<{tag} {attrs}/>")
    return "".join(out), vb


# ------------------------------------------------------------ icon files
def restyle_file(src: Path, dst: Path) -> bool:
    text = src.read_text(errors="ignore")
    if "<image" in text or "Gradient" in text or "<style" in text:
        return False  # artwork or CSS-styled icon, not a plain glyph
    colours = {c.lower() for c in re.findall(r'(?:fill|stroke)\s*[:=]\s*"?\s*(#[0-9a-fA-F]{3,8}|black|currentColor)', text)}
    colours -= {"#fff", "#ffffff", "#fffffe"}
    if len(colours) > 1:
        return False  # several colours: an illustration, keep it
    try:
        root = ET.fromstring(text)
    except ET.ParseError:
        return False
    vb = root.get("viewBox") or f'0 0 {root.get("width", "16").rstrip("px")} {root.get("height", "16").rstrip("px")}'
    try:
        x, y, w, h = (float(v) for v in vb.replace(",", " ").split())
    except ValueError:
        return False
    recoloured = 0
    explicit_white = 0
    for el in root.iter():
        for attr in ("fill", "stroke"):
            v = (el.get(attr) or "").strip().lower()
            if v in ("#fff", "#ffffff", "white"):
                explicit_white += 1
            elif v and v not in ("none", "transparent"):
                el.set(attr, "url(#eg)")
                recoloured += 1
        style = el.get("style")
        if style:
            style = re.sub(r"(fill|stroke)\s*:\s*(#[0-9a-fA-F]{3,8}|black|currentColor)", r"\1:url(#eg)", style)
            el.set("style", style)
    if recoloured == 0 and explicit_white:
        return False  # a white icon for coloured backgrounds: keep Nextcloud's
    if not root.get("fill"):
        root.set("fill", "url(#eg)")
    body = ET.tostring(root, encoding="unicode")
    body = re.sub(r"(<svg[^>]*>)", lambda m: m.group(1) + defs(x, y, w, h), body, count=1)
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(body + "\n")
    return True


def restyle_files(nc: Path) -> int:
    count = 0
    sources = [(nc / "core" / "img" / "actions", THEME / "core" / "img" / "actions")]
    sources += [(nc / "core" / "img" / "places", THEME / "core" / "img" / "places")]
    for app in APPS:
        sources.append((nc / "apps" / app / "img", THEME / "apps" / app / "img"))
    for src_dir, dst_dir in sources:
        if not src_dir.is_dir():
            continue
        for src in sorted(src_dir.glob("*.svg")):
            name = src.name
            if "white" in name or name.endswith("-light.svg") or "logo" in name:
                continue  # drawn for dark backgrounds or brand artwork
            if restyle_file(src, dst_dir / name):
                count += 1
    return count


# --------------------------------------------------------------- vue icons
def build_vue(data) -> int:
    UI_DIR.mkdir(parents=True, exist_ok=True)
    css = [
        "/*",
        " * Edalvix Cloud: interface icons in the edalvix.com.br style.",
        " * GENERATED by branding/edalvix/tools/make-ui-icons.py - do not edit by hand.",
        " *",
        " * SPDX-FileCopyrightText: 2026 EDALVIX",
        " * SPDX-License-Identifier: AGPL-3.0-or-later",
        " */",
        "",
        "/* Light icons need a little more light on dark themes */",
        "body { --ex-icon-filter: none; }",
        "body[data-theme-dark], body[data-theme-dark-highcontrast] { --ex-icon-filter: brightness(1.55) saturate(1.1); --background-invert-if-dark: no !important; }",
        "@media (prefers-color-scheme: dark) { body[data-theme-default] { --ex-icon-filter: brightness(1.55) saturate(1.1); --background-invert-if-dark: no !important; } }",
        "",
        "/* Restyled icon files (theme overrides) */",
        'img[src*="/themes/edalvix/core/img/actions/"], img[src*="/themes/edalvix/core/img/places/"], img[src*="/themes/edalvix/apps/"] { filter: var(--ex-icon-filter) !important; }',
        "",
    ]
    n = 0
    for name, d in sorted(data["mdi"].items()):
        if name in SKIP_NAMES or not d:
            continue
        (UI_DIR / f"{name}.svg").write_text(glyph(f'<path d="{d}"/>'))
        sel = f".material-design-icon.{name}:not(:is({EXCLUDE}) *)"
        css.append(f"{sel} {{ background: url('../img/edalvix/ui/{name}.svg') center / contain no-repeat; filter: var(--ex-icon-filter); }}")
        css.append(f"{sel} > svg {{ opacity: 0; }}")
        n += 1
    for item in data["vue"]:
        key, file = item["key"], item["file"]
        if "use" in item:
            url = item["use"]  # mapped to an existing Edalvix icon
        else:
            shapes, vb = svg_shapes(item["svg"])
            if not shapes:
                continue
            (UI_DIR / f"{file}.svg").write_text(glyph(shapes, vb))
            url = f"../img/edalvix/ui/{file}.svg"
        sel = f'.icon-vue:has(path[d^="{key}"]):not(:is({EXCLUDE}) *)'
        css.append(f"/* {item.get('label', file)} */")
        # .icon-vue fills the whole button area; its inner span has the icon's
        # real size. Some icons have no inner span: then the icon itself.
        css.append(f"{sel} > span, {sel}:has(> svg) {{ background: url('{url}') center / contain no-repeat; filter: var(--ex-icon-filter); }}")
        css.append(f"{sel} svg {{ opacity: 0; }}")
        n += 1
    CSS.write_text("\n".join(css) + "\n")
    return n


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--nextcloud", type=Path, help="Nextcloud directory to read icon files from")
    args = ap.parse_args()
    data = json.loads((HERE / "ui-icons.json").read_text())
    print(f"{build_vue(data)} Vue icons -> {UI_DIR} and {CSS}")
    if args.nextcloud:
        print(f"{restyle_files(args.nextcloud)} icon files -> {THEME}/core/img and {THEME}/apps")


if __name__ == "__main__":
    main()
