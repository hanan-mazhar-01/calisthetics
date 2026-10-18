#!/usr/bin/env python3
"""Uploads the exercise thumbnails to Bunny Storage under `thumbnails/`.

Usage:
  python3 tool/bunny_upload_thumbnails.py "<thumbnails folder>" [--dry-run]

Each picture is matched to its exercise video by name (the folder is used to
tell the two "Active Hang" videos apart) and stored as
`thumbnails/<video file name without .mp4>.<hash>.webp`, e.g.
`thumbnails/calesthetics_001_wall_push_up_beginner_v1.<hash>.webp`, so the app
finds it from the exercise's own video file name. Credentials: see
bunny_upload_images.py (never shipped in the app).
"""
import argparse, hashlib, io, os, re, sys
from pathlib import Path
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bunny_upload_images as up  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "lib/features/exercises/data/exercise_catalog.dart"
WIDTH = 800

# Files whose name differs from the exercise name, by video number.
OVERRIDES = {
    "Burpee_thumbnail_20261016174304.jpg": 30,
    "Wall push thumbnail.jpg": 1,
    "Female_trainer_demonstrating_L-Sit_.jpg": 60,
}
# Second copies that are deliberately not used.
SKIP = {"High_Knees_thumbnail_ (2).jpg"}


def norm(x: str) -> str:
    return re.sub(r"[^a-z0-9]", "", x.lower().replace("’", "").replace("'", ""))


def catalog():
    s = CATALOG.read_text()
    ms = list(re.finditer(r"Exercise\(\s*number: (\d+),\s*name: ('(?:[^'\\]|\\.)*'|\"[^\"]*\"),", s))
    out = {}
    for i, m in enumerate(ms):
        rest = s[m.end(): ms[i + 1].start() if i + 1 < len(ms) else len(s)]
        number = int(m.group(1))
        video = int(re.search(r"videoNumber: (\d+)", rest).group(1))
        if number != video:
            continue  # a repeated entry: its twin owns the video
        out[video] = {
            "name": m.group(2)[1:-1].replace("\\'", "'"),
            "file": re.search(r"videoFile:\s*'([^']*)'", rest).group(1),
            "section": re.search(r"sectionId: '([^']*)'", rest).group(1),
        }
    return out


def stem_of(filename: str) -> str:
    f = Path(filename).stem
    f = re.sub(r"(?i)_?(thumbnail|thimbnail|thumbail).*$", "", f)
    return norm(re.sub(r"\d{14}", "", f))


def match(files, cat):
    chosen, problems = {}, []
    for path in sorted(files):
        name = path.name
        if name in SKIP:
            continue
        if name in OVERRIDES:
            video = OVERRIDES[name]
        else:
            cands = [v for v, e in cat.items() if norm(e["name"]) == stem_of(name)]
            if len(cands) > 1:
                folder = norm(path.parent.name)
                cands = [v for v in cands if norm(cat[v]["section"]) in folder] or cands
            if not cands:
                problems.append(f"no exercise for {path}")
                continue
            video = cands[0]
        # two folders can hold the same exercise: keep the one in its own section
        if video in chosen and norm(cat[video]["section"]) not in norm(path.parent.name):
            continue
        chosen[video] = path
    return chosen, problems


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("source")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    cat = catalog()
    files = [p for p in Path(a.source).rglob("*") if p.suffix.lower() in (".jpg", ".jpeg", ".png", ".webp")]
    chosen, problems = match(files, cat)
    for p in problems:
        print("!!", p)
    missing = [f"#{v} {cat[v]['name']}" for v in sorted(cat) if v not in chosen]
    if missing:
        print("Exercises without a thumbnail:", ", ".join(missing))
    if not a.dry_run:
        up.load_env()
    versions, total = {}, 0
    previous = {}
    if up.OUT_DART.exists():
        previous = {m.group(1): m.group(2) for m in re.finditer(r"'([^']+)':\s*'([0-9a-f]+)'", up.OUT_DART.read_text())}
    for video, path in sorted(chosen.items()):
        key = "thumbnails/" + cat[video]["file"].removesuffix(".mp4")
        im = Image.open(path).convert("RGB")
        h = round(WIDTH * 896 / 1200)  # every thumbnail is shown 1200:896
        # crop to that ratio (centred) before resizing, so odd-sized pictures fit
        r = 1200 / 896
        if im.width / im.height > r:
            w2 = round(im.height * r); x = (im.width - w2) // 2
            im = im.crop((x, 0, x + w2, im.height))
        else:
            h2 = round(im.width / r); y = (im.height - h2) // 2
            im = im.crop((0, y, im.width, y + h2))
        im = im.resize((WIDTH, h), Image.LANCZOS)
        buf = io.BytesIO(); im.save(buf, "WEBP", quality=82, method=6)
        data = buf.getvalue(); total += len(data)
        versions[key] = hashlib.sha1(data).hexdigest()[:8]
        print(f"{len(data)//1024:4d} KB  {key}.{versions[key]}.webp  <- {path.parent.name}/{path.name}")
        if not a.dry_run:
            up.put(f"{key}.{versions[key]}.webp", data)
            if previous.get(key) not in (None, versions[key]):
                up.delete(f"{key}.{previous[key]}.webp")
    print(f"\n{len(versions)} thumbnails, {total/1e6:.1f} MB")
    if not a.dry_run:
        previous.update(versions)
        body = "".join(f"  '{k}': '{v}',\n" for k, v in sorted(previous.items()))
        up.OUT_DART.write_text(
            "// GENERATED by tool/bunny_upload_images.py and tool/bunny_upload_thumbnails.py\n"
            "// - do not edit by hand.\n"
            "// Image key (folder/name, no extension) -> content hash, used in the file name.\n"
            f"const bunnyImageVersions = <String, String>{{\n{body}}};\n")
        print("Updated", up.OUT_DART.name)


if __name__ == "__main__":
    main()
