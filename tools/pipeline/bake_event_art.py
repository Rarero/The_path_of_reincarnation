#!/usr/bin/env python3
"""이벤트 전용 조형 후처리 (요청서 026).

PixelLab에서 내려받은 zip 또는 png를 인게임 규격으로 옮긴다.
pixellab/_incoming/ 아래에 파일을 두고 실행하면 이름과 크기를 맞춰 assets/로 굽는다.

사용법: python tools/pipeline/bake_event_art.py
입력: pixellab/_incoming/*.zip 또는 *.png (파일명 앞부분으로 용도를 가른다)
  gambler_idle, gambler_idle2, gambler_win, gambler_lose
  fence_run_0 ~ fence_run_3
  chase_crate, chase_jars, chase_cart
산출:
  assets/sprites/enemies/gambler_*.png      (원본 크기 유지, 알파 이진화)
  assets/sprites/enemies/fence_back_run.png (76x76 프레임 가로 연결)
  assets/sprites/props/chase_*.png          (원본 크기 유지)

알파 이진화 기준과 캐릭터 캔버스 규격은 tools/pipeline/bake_wrestler.py와 같다.
"""

from __future__ import annotations

import sys
import zipfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent.parent
INCOMING = ROOT / "pixellab/_incoming"
ENEMIES = ROOT / "assets/sprites/enemies"
PROPS = ROOT / "assets/sprites/props"

# 캐릭터 캔버스 규격 (다른 캐릭터와 같아야 코드 수정 없이 붙는다)
FRAME = 76
ART_CENTER = (40, 57)
# 알파 이진화 문턱
ALPHA_CUT = 128
# 생성 원본이 화면에서 너무 커서 줄인다. 정수배가 아니라 알파 이진화로 가장자리를 다시 세운다.
# 노름꾼 0.6은 관중(25px)과 위계가 맞는 크기, 장물아비 0.6은 플레이어(26px)와 맞는 크기다
GAMBLER_SHRINK = 0.6
FENCE_SHRINK = 0.6

GAMBLER_KEYS = ("gambler_idle", "gambler_idle2", "gambler_win", "gambler_lose")
FENCE_KEYS = ("fence_run_0", "fence_run_1", "fence_run_2", "fence_run_3")
PROP_KEYS = ("chase_crate", "chase_jars", "chase_cart")


def binarize(image: Image.Image) -> Image.Image:
    out = image.convert("RGBA")
    pixels = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = pixels[x, y]
            pixels[x, y] = (r, g, b, 255 if a >= ALPHA_CUT else 0)
    return out


def load_source(stem: str) -> Image.Image | None:
    png = INCOMING / (stem + ".png")
    if png.exists():
        return Image.open(png).convert("RGBA")
    archive = INCOMING / (stem + ".zip")
    if not archive.exists():
        return None
    with zipfile.ZipFile(archive) as zf:
        names = [n for n in zf.namelist() if n.endswith(".png")]
        if not names:
            return None
        with zf.open(sorted(names)[0]) as handle:
            return Image.open(handle).convert("RGBA").copy()


def trim(image: Image.Image) -> Image.Image:
    box = image.getbbox()
    return image.crop(box) if box else image


def union_box(images: list[Image.Image]):
    """여러 컷의 내용이 모두 들어가는 하나의 상자. 컷마다 따로 자르면 자세가 어긋난다."""
    boxes = [im.getbbox() for im in images if im.getbbox()]
    if not boxes:
        return None
    return (
        min(b[0] for b in boxes),
        min(b[1] for b in boxes),
        max(b[2] for b in boxes),
        max(b[3] for b in boxes),
    )


def shrink_ratio(image: Image.Image, ratio: float) -> Image.Image:
    size = (max(1, int(round(image.width * ratio))), max(1, int(round(image.height * ratio))))
    return image.resize(size, Image.NEAREST)


def bake_gambler() -> int:
    sources = [(key, load_source(key)) for key in GAMBLER_KEYS]
    sources = [(k, v) for k, v in sources if v is not None]
    if not sources:
        return 0
    box = union_box([v for _, v in sources])
    ENEMIES.mkdir(parents=True, exist_ok=True)
    made = 0
    for key, source in sources:
        # 네 컷을 같은 상자로 자른다. 앉은 높이와 가로 중심이 컷마다 흔들리지 않는다
        art = binarize(shrink_ratio(source.crop(box), GAMBLER_SHRINK))
        out = ENEMIES / (key + ".png")
        art.save(out)
        print("%s  %dx%d" % (out.relative_to(ROOT), art.width, art.height))
        made += 1
    return made


def place_on_frame(art: Image.Image) -> Image.Image:
    """캐릭터를 76x76 캔버스의 가로 중심과 발밑 기준에 놓는다."""
    canvas = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    x = ART_CENTER[0] - art.width // 2
    y = ART_CENTER[1] - art.height
    canvas.alpha_composite(art, (max(x, 0), max(y, 0)))
    return canvas


def bake_fence() -> int:
    sources = [load_source(key) for key in FENCE_KEYS]
    sources = [s for s in sources if s is not None]
    if not sources:
        return 0
    box = union_box(sources)
    frames: list[Image.Image] = []
    for source in sources:
        frames.append(place_on_frame(binarize(shrink_ratio(source.crop(box), FENCE_SHRINK))))
    if not frames:
        return 0
    ENEMIES.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGBA", (FRAME * len(frames), FRAME), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.alpha_composite(frame, (FRAME * i, 0))
    out = ENEMIES / "fence_back_run_n.png"
    sheet.save(out)
    print("%s  %d프레임" % (out.relative_to(ROOT), len(frames)))
    return len(frames)


def bake_props() -> int:
    made = 0
    PROPS.mkdir(parents=True, exist_ok=True)
    for key in PROP_KEYS:
        source = load_source(key)
        if source is None:
            continue
        # 장애물은 줄이지 않는다. 화면에서 깊이 배율(0.52~1.0)이 크기를 잡는다
        art = binarize(trim(source))
        out = PROPS / (key + ".png")
        art.save(out)
        print("%s  %dx%d" % (out.relative_to(ROOT), art.width, art.height))
        made += 1
    return made


def main() -> int:
    if not INCOMING.is_dir():
        print("입력 폴더가 없다: %s" % INCOMING.relative_to(ROOT))
        return 2
    total = bake_gambler() + bake_fence() + bake_props()
    if total == 0:
        print("구울 파일이 없다. pixellab/_incoming/에 zip이나 png를 두고 다시 실행한다")
        return 1
    print("완료. %d건" % total)
    return 0


if __name__ == "__main__":
    sys.exit(main())
