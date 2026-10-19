#!/usr/bin/env python3
"""Builds the Privacy Policy and Terms of Service pages from tool/legal_content.py.

  python3 tool/build_legal_pages.py
  PRIVACY_URL=https://.../privacy TERMS_URL=https://.../terms python3 tool/build_legal_pages.py

Writes
  legal_pages/privacy-policy.html      one self-contained page (inline styles)
  legal_pages/terms-of-service.html    one self-contained page
  lib/features/legal/domain/legal_text.dart   the same text for the in-app screen

Each page is a single <div> with every style inline, so it can be pasted into
a Blogger page's HTML view as it is (Blogger drops <style> blocks and the
<html>/<head> tags, never inline styles). The links between the two pages
default to the file names; set PRIVACY_URL / TERMS_URL (the Blogger addresses)
and run again so the pages point at each other online.
"""
import html
import json
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import legal_content as C  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "legal_pages"
OUT_DART = ROOT / "lib/features/legal/domain/legal_text.dart"

PRIVACY_URL = os.environ.get("PRIVACY_URL", "privacy-policy.html")
TERMS_URL = os.environ.get("TERMS_URL", "terms-of-service.html")

# Calesthetics colours (lib/core/theme/app_colors.dart), light theme.
INK = "#191719"        # headings
BODY = "#4A4447"       # body text
MUTED = "#746D70"      # small print
FAINT = "#9A9094"
LINE = "#E9DFE0"       # rules and borders
ROSE = "#D85F70"       # the app's accent
ROSE_DEEP = "#B94A5B"  # accent text that must read on white
MIST = "#FBE9EC"       # soft rose fills
MIST_LINE = "#F1C6CB"
BOX_BG = "#FDF1F3"
BOX_TITLE = "#8A2D3E"
BOX_TEXT = "#9B3A4A"
PANEL = "#FAF6F6"
CODE_BG = "#F5EEEE"

FONT = ("Poppins, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, "
        "Helvetica, Arial, sans-serif")
SERIF = "Lora, Georgia, 'Times New Roman', serif"
FONT_LINK = ('<link href="https://fonts.googleapis.com/css2?family=Lora:wght@500'
             '&family=Poppins:wght@400;500;600;700&display=swap" '
             'rel="stylesheet">')


def esc(text):
    return html.escape(text, quote=False)


def link(href, label):
    return (f'<a href="{href}" style="color: {ROSE_DEEP}; font-weight: 600; '
            f'text-decoration: none;">{label}</a>')


def inline(text):
    """Escape, then **bold** and the [[...]] link tokens."""
    t = esc(text)
    t = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", t)
    t = t.replace("[[email]]", link(f"mailto:{C.EMAIL}", C.EMAIL))
    t = t.replace("[[privacy]]", link(PRIVACY_URL, "Privacy Policy"))
    t = t.replace("[[terms]]", link(TERMS_URL, "Terms of Service"))
    return t


def ascii_only(s):
    """Non-ASCII characters become &#...; so the file is pure ASCII."""
    return s.encode("ascii", "xmlcharrefreplace").decode("ascii")


def h2(n, title, first):
    top = 30 if first else 35
    return (f'<h2 style="border-bottom: 1px solid {LINE}; color: {INK}; '
            f'font-size: 22px; font-weight: 700; margin-top: {top}px; '
            f'padding-bottom: 8px;">{n}. {esc(title)}</h2>')


def block(b):
    kind = b[0]
    if kind == "p":
        return (f'<p style="color: {BODY}; font-size: 15px;">'
                f'{inline(b[1])}</p>')
    if kind == "h3":
        return (f'<h3 style="color: #2B2629; font-size: 17px; font-weight: 600; '
                f'margin-top: 20px;">{esc(b[1])}</h3>')
    if kind == "ul":
        items = "".join(
            f'<li style="margin-bottom: 8px;">{inline(i)}</li>' for i in b[1])
        return (f'<ul style="color: {BODY}; font-size: 15px; margin-bottom: '
                f'16px; padding-left: 20px;">{items}</ul>')
    if kind == "code":
        return (f'<div style="background-color: {CODE_BG}; border-radius: 6px; '
                f'color: {INK}; font-family: monospace; font-size: 13px; '
                f'margin: 8px 0px 14px; padding: 10px 14px;">{esc(b[1])}</div>')
    if kind == "warn":
        return (
            '<div style="background-color: #fffbeb; border-left: 4px solid '
            'rgb(245, 158, 11); border-radius: 8px; margin: 16px 0px; '
            'padding: 16px 20px;">'
            f'<p style="color: #92400e; font-size: 14px; font-weight: 700; '
            f'margin: 0px 0px 8px;">{esc(b[1])}</p>'
            f'<p style="color: #b45309; font-size: 13.5px; line-height: 1.6; '
            f'margin: 0px;">{inline(b[2])}</p></div>')
    if kind == "contact":
        rows = "".join(
            f'<p style="color: {INK}; font-size: 15px; margin: 0px 0px 6px;">'
            f'<b>{esc(k)}:</b> {inline(v)}</p>' for k, v in b[1])
        return (f'<div style="background-color: {PANEL}; border-radius: 8px; '
                f'border: 1px solid {LINE}; margin-top: 14px; '
                f'padding: 18px 22px;">{rows}</div>')
    raise ValueError(kind)


def page(doc):
    icon, box_title, box_text = doc["box"]
    parts = [
        '<div style="color: #1f2937; font-family: ' + FONT + '; '
        'line-height: 1.7; margin: 0px auto; max-width: 800px; '
        'padding: 20px 10px;">',
        # header
        f'<div style="border-bottom: 2px solid {LINE}; margin-bottom: 30px; '
        f'padding-bottom: 20px; text-align: center;">',
        f'<span style="background-color: {MIST}; border-radius: 9999px; '
        f'border: 1px solid {MIST_LINE}; color: {ROSE_DEEP}; '
        f'display: inline-block; font-size: 12px; font-weight: 700; '
        f'letter-spacing: 0.8px; margin-bottom: 12px; padding: 4px 12px; '
        f'text-transform: uppercase;">{esc(doc["badge"])}</span>',
        f'<h1 style="color: {INK}; font-size: 32px; font-weight: 700; '
        f'letter-spacing: -0.5px; margin: 0px 0px 10px;">{esc(doc["title"])} '
        f'for <span style="color: {ROSE}; font-family: {SERIF}; '
        f'font-weight: 500;">{C.APP}</span></h1>',
        f'<p style="color: {MUTED}; font-size: 14px; margin: 0px;">'
        f'<b>Effective Date:</b> {C.EFFECTIVE} &nbsp;|&nbsp; '
        f'<b>Last Updated:</b> {C.UPDATED}</p>',
        f'<p style="color: {FAINT}; font-size: 13px; margin: 5px 0px 0px;">'
        f'Application: <b>{C.APP}</b> &nbsp;|&nbsp; Publisher: '
        f'<b>{C.PUBLISHER}</b></p>',
        '</div>',
        # principle box
        f'<div style="background-color: {BOX_BG}; border-left: 4px solid '
        f'{ROSE}; border-radius: 8px; margin-bottom: 30px; '
        f'padding: 16px 20px;">',
        f'<p style="color: {BOX_TITLE}; font-size: 16px; font-weight: 700; '
        f'margin: 0px 0px 6px;">{icon} {esc(box_title)}</p>',
        f'<p style="color: {BOX_TEXT}; font-size: 14px; margin: 0px;">'
        f'{inline(box_text)}</p>',
        '</div>',
    ]
    for i, sec in enumerate(doc["sections"], 1):
        parts.append(h2(i, sec["title"], i == 1))
        parts.extend(block(b) for b in sec["blocks"])
    parts.append(
        f'<p style="color: {FAINT}; font-size: 12.5px; margin: 30px 0px 0px; '
        f'text-align: center;">&copy; 2026 {C.PUBLISHER}. All rights '
        f'reserved.</p>')
    parts.append("</div>")
    body = "\n".join(parts)
    head = (
        "<!-- Calesthetics - " + doc["title"] + ". Generated by "
        "tool/build_legal_pages.py: edit tool/legal_content.py, not this file.\n"
        "     Blogger: New page > HTML view > paste everything below this "
        "comment. -->\n"
        '<meta charset="utf-8">\n' + FONT_LINK + "\n")
    return ascii_only(head + body + "\n")


# ------------------------------------------------------------- in-app copy --
def plain(text):
    t = re.sub(r"\*\*(.+?)\*\*", r"\1", text)
    t = t.replace("[[email]]", C.EMAIL)
    t = t.replace("[[privacy]]", "Privacy Policy")
    t = t.replace("[[terms]]", "Terms of Service")
    return t


def strip_emoji(text):
    return re.sub(r"[\U00010000-\U0010FFFF☀-➿️]+\s*", "", text)


def flatten(blocks):
    out = []
    for b in blocks:
        kind = b[0]
        if kind == "p":
            out.append(plain(b[1]))
        elif kind == "h3":
            out.append(plain(b[1]))
        elif kind == "ul":
            out.append("\n".join("• " + plain(i) for i in b[1]))
        elif kind == "code":
            out.append(b[1])
        elif kind == "warn":
            out.append(plain(strip_emoji(b[1])) + ". " + plain(b[2]))
        elif kind == "contact":
            out.append("\n".join(f"{k}: {plain(v)}" for k, v in b[1]))
    return "\n\n".join(out)


def dart_str(s):
    # A Dart string literal: keep real characters, escape what Dart reads.
    s = s.replace("\\", "\\\\").replace('"', '\\"').replace("$", "\\$")
    return '"' + s.replace("\n", "\\n") + '"'


def dart_sections(name, doc):
    lines = [f"const {name} = <LegalSection>["]
    for i, sec in enumerate(doc["sections"], 1):
        lines.append("  LegalSection(")
        lines.append(f"    {dart_str(f'{i}. ' + sec['title'])},")
        lines.append(f"    {dart_str(flatten(sec['blocks']))},")
        lines.append("  ),")
    lines.append("];")
    return "\n".join(lines)


def dart():
    intro = [
        ("The in-app copy of the Privacy Policy and the Terms of Service. "
         "GENERATED by"),
        "tool/build_legal_pages.py from tool/legal_content.py: edit the text "
        "there and run",
        "the script, so the app and the web pages (legal_pages/) always say "
        "the same.",
    ]
    head = "\n".join("/// " + l for l in intro) + "\n"
    cls = ("class LegalSection {\n"
           "  const LegalSection(this.heading, this.body);\n"
           "  final String heading;\n  final String body;\n}\n")
    return (head + cls + f"\nconst legalUpdated = {dart_str(C.UPDATED)};\n\n"
            + dart_sections("privacySections", C.PRIVACY) + "\n\n"
            + dart_sections("termsSections", C.TERMS) + "\n")


def main():
    OUT_DIR.mkdir(exist_ok=True)
    for doc, name in ((C.PRIVACY, "privacy-policy.html"),
                      (C.TERMS, "terms-of-service.html")):
        (OUT_DIR / name).write_text(page(doc), encoding="utf-8")
        print("wrote", (OUT_DIR / name).relative_to(ROOT))
    OUT_DART.write_text(dart(), encoding="utf-8")
    print("wrote", OUT_DART.relative_to(ROOT))


if __name__ == "__main__":
    main()
