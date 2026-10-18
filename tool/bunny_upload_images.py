#!/usr/bin/env python3
"""Optimises a folder of images and uploads it to Bunny Storage.

Usage:
  python3 tool/bunny_upload_images.py "<source folder>" [--prefix onboarding] [--dry-run]

Credentials are read from ~/.config/calesthetics/bunny.env (or the environment):
  BUNNY_STORAGE_ZONE, BUNNY_STORAGE_KEY, BUNNY_STORAGE_HOST, BUNNY_CDN_HOST
The storage key never goes into the app or the repository. Only the public
CDN host is used by the app.

Every image becomes a WebP (transparency kept), is renamed to a URL-safe slug
and keeps its folder. A generated Dart file lists each image's content hash so
the app can cache-bust when a picture is replaced.
"""
import argparse, hashlib, io, json, os, re, sys, urllib.error, urllib.request
from pathlib import Path
from PIL import Image

ENV = Path.home() / ".config/calesthetics/bunny.env"
OUT_DART = Path(__file__).resolve().parent.parent / "lib/features/media/data/bunny_image_versions.g.dart"
MAX_SIDE = 1000
LARGE_SIDE = 1400
LARGE = {"welcome-hero", "where-should-we-focus"}
NO_TRIM = {"welcome-hero"}
ALIASES = {"four-women-in-colorful-outfits": "welcome-hero"}


def load_env(required=("BUNNY_STORAGE_ZONE", "BUNNY_STORAGE_KEY", "BUNNY_STORAGE_HOST")):
    if ENV.exists():
        for line in ENV.read_text().splitlines():
            if "=" in line and not line.lstrip().startswith("#"):
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip())
    for k in required:
        if not os.environ.get(k):
            sys.exit(f"Missing {k} (set it in {ENV})")


def slug(name: str) -> str:
    s = Path(name).stem
    s = re.sub(r"_?\d{14}", "", s)          # timestamps added by the bg remover
    s = re.sub(r"_?nobg$", "", s, flags=re.I)
    s = s.strip().lower().replace("&", "and").replace("+", "-plus")
    s = re.sub(r"\((\d+)\)", r"-\1", s)
    s = re.sub(r"[^a-z0-9-]+", "-", s)
    s = re.sub(r"-+", "-", s).strip("-")
    return ALIASES.get(s, s)


def optimise(path: Path, name: str) -> bytes:
    im = Image.open(path).convert("RGBA")
    if name not in NO_TRIM:
        # Cut-out pictures come on a big transparent canvas; crop to the
        # visible subject (plus a small margin) so it fills its slot.
        alpha = im.getchannel("A").point(lambda v: 255 if v > 24 else 0)
        box = alpha.getbbox()
        if box:
            pad = int(max(box[2] - box[0], box[3] - box[1]) * 0.04)
            im = im.crop((max(0, box[0] - pad), max(0, box[1] - pad),
                          min(im.width, box[2] + pad), min(im.height, box[3] + pad)))
    side = LARGE_SIDE if name in LARGE else MAX_SIDE
    if max(im.size) > side:
        im.thumbnail((side, side), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "WEBP", quality=84, alpha_quality=90, method=6)
    return buf.getvalue()


def delete(remote: str):
    url = f"https://{os.environ['BUNNY_STORAGE_HOST']}/{os.environ['BUNNY_STORAGE_ZONE']}/{remote}"
    req = urllib.request.Request(url, method="DELETE", headers={"AccessKey": os.environ["BUNNY_STORAGE_KEY"]})
    try:
        urllib.request.urlopen(req).read()
    except urllib.error.HTTPError as e:
        if e.code != 404:
            raise


def put(remote: str, data: bytes):
    url = f"https://{os.environ['BUNNY_STORAGE_HOST']}/{os.environ['BUNNY_STORAGE_ZONE']}/{remote}"
    req = urllib.request.Request(url, data=data, method="PUT", headers={
        "AccessKey": os.environ["BUNNY_STORAGE_KEY"],
        "Content-Type": "application/octet-stream",
    })
    with urllib.request.urlopen(req) as r:
        if r.status not in (200, 201):
            sys.exit(f"Upload failed {r.status} for {remote}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("source")
    ap.add_argument("--prefix", default="onboarding")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    if not a.dry_run:
        load_env()
    src = Path(a.source)
    versions, total_in, total_out = {}, 0, 0
    previous = {}
    if OUT_DART.exists():
        previous = {m.group(1): m.group(2) for m in re.finditer(r"'([^']+)':\s*'([0-9a-f]+)'", OUT_DART.read_text())}
    for p in sorted(src.rglob("*")):
        if p.suffix.lower() not in (".png", ".jpg", ".jpeg", ".webp"):
            continue
        rel = p.relative_to(src)
        folder = "/".join(slug(part) for part in rel.parts[:-1])
        name = slug(p.name)
        key = "/".join(x for x in (a.prefix, folder, name) if x)
        data = optimise(p, name)
        total_in += p.stat().st_size
        total_out += len(data)
        if key in versions:
            sys.exit(f"Two files map to the same name: {key}")
        versions[key] = hashlib.sha1(data).hexdigest()[:8]
        print(f"{len(data)//1024:5d} KB  {key}.{versions[key]}.webp   <- {rel}")
        if not a.dry_run:
            # The hash is part of the file name, so a changed picture is a new
            # URL and no CDN cache can ever serve a stale copy.
            put(f"{key}.{versions[key]}.webp", data)
            if previous.get(key) not in (None, versions[key]):
                delete(f"{key}.{previous[key]}.webp")
            delete(f"{key}.webp")  # the old un-hashed name
    print(f"\n{len(versions)} images, {total_in/1e6:.1f} MB -> {total_out/1e6:.1f} MB")
    if not a.dry_run:
        existing = {}
        if OUT_DART.exists():
            existing = {m.group(1): m.group(2) for m in re.finditer(r"'([^']+)':\s*'([0-9a-f]+)'", OUT_DART.read_text())}
        existing.update(versions)
        body = "".join(f"  '{k}': '{v}',\n" for k, v in sorted(existing.items()))
        OUT_DART.write_text(
            "// GENERATED by tool/bunny_upload_images.py - do not edit by hand.\n"
            "// Image key (folder/name, no extension) -> content hash, used as ?v=.\n"
            f"const bunnyImageVersions = <String, String>{{\n{body}}};\n")
        print(f"Wrote {OUT_DART.relative_to(Path.cwd()) if OUT_DART.is_relative_to(Path.cwd()) else OUT_DART}")


if __name__ == "__main__":
    main()
