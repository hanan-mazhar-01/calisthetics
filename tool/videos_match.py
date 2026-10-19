#!/usr/bin/env python3
"""Matches the raw exercise videos to the catalog.

Each catalog video has a ~30 s main video and a ~10 s clip (the clip shown
during rest, before the exercise). Main vs clip is told by duration, not by
name. When an exercise has several clips, the one whose first frame matches
the main video's first frame wins (the clip is the main video's first take).

  python3 tool/videos_match.py <videos folder>   -> prints the match table
"""
import json, os, re, subprocess, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bunny_upload_thumbnails import catalog, norm  # noqa: E402

FFMPEG = os.environ.get("FFMPEG", "ffmpeg")
FFPROBE_LIKE = FFMPEG

# Names in the folder that differ from the catalog name (normalised).
ALIASES = {
    "wallpush": "wallpushup", "kneepush": "kneepushup", "chairbox": "chairboxsquat",
    "chairboxsquat": "chairboxsquat", "benchbarsupporthold": "benchbarsupporthold",
    "lowimpactjumping": "lowimpactjumpingjack", "supportedsplit": "supportedsplitsquat",
    "singlelegglute": "singlelegglutebridge", "footassistedchin": "footassistedchinup",
    "bentkneelegrise": "bentkneelegraise", "assisteddipsupport": "assisteddipsupporthold",
    "assistedonearmpushup": "assistedonearmpushupprogression",
    "slowbreathingrelaxation": "slowbreathingrelaxation",
    "marchinplacebeginner": "marchinplace", "burpee": "burpeestepbackvariation", "pikepushup": "pikepushup",
    "bentkneeraise": "bentkneelegraise", "controlledraise": "controlledhanginglegraise",
    "controlledhangingleg": "controlledhanginglegraise",
}


def duration(path):
    out = subprocess.run([FFMPEG, "-i", str(path)], capture_output=True, text=True).stderr
    m = re.search(r"Duration: (\d+):(\d+):([\d.]+)", out)
    return int(m.group(1)) * 3600 + int(m.group(2)) * 60 + float(m.group(3)) if m else 0


def stem(name):
    s = Path(name).stem
    s = re.sub(r"(?i)\(\d+\)", "", s)
    s = re.sub(r"(?i)[ _]*(1st[ _]?clip|clip[ _]*\d*|clip_)\b.*$", "", s)
    s = re.sub(r"(?i)_?1080p.*$", "", s)
    s = re.sub(r"(?i)_1$", "", s)
    s = re.sub(r"\d{14}", "", s)
    k = norm(s)
    return ALIASES.get(k, k)


def frame(path, t=0.5):
    raw = subprocess.run(
        [FFMPEG, "-loglevel", "error", "-ss", str(t), "-i", str(path), "-frames:v", "1",
         "-vf", "scale=32:56,format=gray", "-f", "rawvideo", "-"],
        capture_output=True).stdout
    return raw


def diff(a, b):
    if not a or not b or len(a) != len(b):
        return 1e9
    return sum(abs(x - y) for x, y in zip(a, b)) / len(a)


def match(folder):
    cat = catalog()
    by_name = {}
    for v, e in cat.items():
        by_name.setdefault(norm(e["name"]), []).append(v)
    files = sorted(Path(folder).rglob("*.mp4"))
    mains, clips, unknown = {}, {}, []
    for f in files:
        k = stem(f.name)
        cands = by_name.get(k, [])
        if len(cands) > 1:  # e.g. two "Active Hang" videos: tell by folder
            folder_key = norm(str(f.parent))
            pick = [v for v in cands if norm(cat[v]["section"]).replace("skill", "") in folder_key]
            cands = pick or cands
        if not cands:
            unknown.append(str(f.relative_to(folder)))
            continue
        v = cands[0]
        d = duration(f)
        (clips if d < 20 else mains).setdefault(v, []).append(f)
    result = {}
    for v in sorted(cat):
        main = sorted(mains.get(v, []), key=lambda p: (len(p.name), p.name))
        main = main[0] if main else None
        cl = clips.get(v, [])
        if len(cl) > 1 and main is not None:
            ref = frame(main)
            cl = sorted(cl, key=lambda p: diff(frame(p), ref))
        result[v] = {
            "name": cat[v]["name"],
            "file": cat[v]["file"],
            "main": str(main) if main else None,
            "clip": str(cl[0]) if cl else None,
        }
    return result, unknown


if __name__ == "__main__":
    res, unknown = match(sys.argv[1])
    root = Path(sys.argv[1])
    for v, r in res.items():
        m = Path(r["main"]).relative_to(root) if r["main"] else "-- MISSING --"
        c = Path(r["clip"]).relative_to(root) if r["clip"] else "-- MISSING --"
        print(f"#{v:3d} {r['name'][:30]:30s} | main: {m} | clip: {c}")
    print("\nNot matched to any exercise:", unknown)
    json.dump(res, open("/tmp/video_match.json", "w"), indent=1)
