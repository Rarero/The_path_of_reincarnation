#!/usr/bin/env python3
"""문얼굴 보스 아트 후처리 (2026-08-09 작성, 2026-08-10 증기 추가).

PixelLab 생성물을 게임 자산 규격으로 바꾼다. 하는 일은 네 가지다.

1. 대문 정면 프레임을 좌우 문짝 두 장으로 정확히 반씩 쪼갠다
2. 낙석과 바람 장애물 시트(4x4 격자)를 낱장으로 쪼갠다
3. 증기 오브젝트 묶음에서 파티클용 퍼프를 뽑고, 가로로 이어 붙는 증기 띠를 조립한다
4. 전부 약한 야간 보정을 건다

팔레트 하드 양자화는 쓰지 않는다. act1_night_nofire.gpl에 중간 갈색 단계가 없어
대문과 항아리와 궤짝이 한 가지 모래색으로 뭉개졌다 (2026-08-09 판단, DECISIONS.md).

캔버스 크기 = 인게임 크기 원칙(ART_STYLE)을 지키므로 확대 축소는 정수배만 쓴다.

사용법:
    python3 tools/build_boss_art.py --gate art_src/.../gate_south.png
    python3 tools/build_boss_art.py --rocks art_src/.../rocks.png
    python3 tools/build_boss_art.py --props art_src/.../props.png
    python3 tools/build_boss_art.py --steam art_src/.../steam_objects_dir

의존: pillow
"""

from __future__ import annotations

import argparse
import random
import sys
from pathlib import Path

try:
    from PIL import Image, ImageEnhance
except ImportError:  # pragma: no cover
    sys.exit("pillow가 필요하다: pip install pillow")

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "sprites" / "bosses"

## 문짝 한 짝의 인게임 규격 (docs/act1/BOSS.md 3.1 크기 규격)
LEAF_W = 76
LEAF_H = 192
## 낙석과 장애물 낱장의 최대 변
DEBRIS_MAX = 48
## 증기 띠 규격. 가로는 타일 폭, 세로는 보스 스크립트의 STEAM_HEIGHT와 같아야 한다
BAND_W = 128
BAND_H = 104
## 증기 띠 조립 난수 시드. 고정해야 다시 돌려도 같은 그림이 나온다
BAND_SEED = 20260810


def night(img: Image.Image, sat: float = 0.82, cool: float = 0.10) -> Image.Image:
    """약한 야간 보정. 채도를 낮추고 어두운 쪽에만 한색을 섞는다."""
    rgba = img.convert("RGBA")
    alpha = rgba.getchannel("A")
    rgb = ImageEnhance.Color(rgba.convert("RGB")).enhance(sat)
    px = rgb.load()
    for y in range(rgb.height):
        for x in range(rgb.width):
            r, g, b = px[x, y]
            lum = (r * 30 + g * 59 + b * 11) / 100 / 255.0
            k = cool * (1.0 - lum)
            px[x, y] = (
                int(r * (1 - k * 0.9)),
                int(g * (1 - k * 0.6)),
                min(255, int(b + (70 - b) * k)),
            )
    rgb.putalpha(alpha)
    return rgb


def neutral(img: Image.Image, sat: float = 0.35) -> Image.Image:
    """증기 전용 보정. 색을 거의 빼서 인게임 modulate가 깨끗하게 물들게 한다.

    증기는 예고에서 붉게, 분출에서 따뜻한 흰색으로 색이 바뀐다. 원본에 색이 남아 있으면
    두 색이 섞여 탁해진다. 야간 보정 대신 이 쪽을 쓴다.
    """
    rgba = img.convert("RGBA")
    alpha = rgba.getchannel("A")
    rgb = ImageEnhance.Color(rgba.convert("RGB")).enhance(sat)
    rgb.putalpha(alpha)
    return rgb


def trim(img: Image.Image) -> Image.Image:
    box = img.convert("RGBA").getbbox()
    return img.crop(box) if box else img


def half(img: Image.Image) -> Image.Image:
    return img.resize((max(1, img.width // 2), max(1, img.height // 2)), Image.Resampling.NEAREST)


def split_gate(path: Path) -> None:
    """대문 정면 프레임을 좌우 문짝으로 정확히 반씩 쪼갠다.

    문틈을 찾아 자르지 않고 한가운데를 자르는 이유가 있다. 두 장을 나란히 붙였을 때
    한 픽셀이라도 어긋나면 세로 실틈이 보여 "완전히 닫힌 문"으로 읽히지 않는다
    (2026-08-10 사용자 보고 1번).
    """
    src = trim(Image.open(path).convert("RGBA"))
    seam = src.width // 2
    left = src.crop((0, 0, seam, src.height))
    right = src.crop((seam, 0, src.width, src.height))
    OUT.mkdir(parents=True, exist_ok=True)
    night(left).save(OUT / "muneolgul_leaf_angry.png")
    night(right).save(OUT / "muneolgul_leaf_calm.png")
    print(f"  기록: muneolgul_leaf_angry/calm.png ({left.width}x{left.height})")
    if (left.width, left.height) != (LEAF_W, LEAF_H):
        print(f"  경고: 규격 {LEAF_W}x{LEAF_H}와 다르다. BOSS.md 크기 규격을 함께 고쳐라")


def split_sheet(path: Path, prefix: str, count: int) -> None:
    """4x4 격자 시트를 낱장으로 쪼갠다. 내용이 있는 칸만 큰 것부터 count개 고른다."""
    src = Image.open(path).convert("RGBA")
    cw, ch = src.width // 4, src.height // 4
    cells: list[tuple[int, Image.Image]] = []
    for row in range(4):
        for col in range(4):
            cell = src.crop((col * cw, row * ch, (col + 1) * cw, (row + 1) * ch))
            box = cell.getbbox()
            if box is None:
                continue
            cropped = cell.crop(box)
            if cropped.width * cropped.height < 36:
                continue
            cells.append((cropped.width * cropped.height, cropped))
    cells.sort(key=lambda t: -t[0])
    print(f"  내용이 있는 칸 {len(cells)}개 중 {count}개 사용")
    OUT.mkdir(parents=True, exist_ok=True)
    for i, (_, cell) in enumerate(cells[:count], start=1):
        img = cell
        scale = max(img.width, img.height) / DEBRIS_MAX
        if scale > 1.0:
            k = max(2, round(scale))
            img = img.resize((max(1, img.width // k), max(1, img.height // k)), Image.Resampling.NEAREST)
        night(img).save(OUT / f"{prefix}_{i:02d}.png")
        print(f"  기록: {prefix}_{i:02d}.png ({img.width}x{img.height})")


def _load_object(root: Path, name: str) -> Image.Image:
    """PixelLab Objects ZIP 해제본에서 낱장을 읽는다 (objects/<이름>/base/rotations/unknown.png)."""
    path = root / name / "base" / "rotations" / "unknown.png"
    if not path.exists():
        sys.exit(f"증기 원본을 찾지 못했다: {path}")
    return trim(Image.open(path).convert("RGBA"))


def build_steam(root: Path) -> None:
    """증기 자산 4종을 만든다.

    퍼프 3종은 파티클(윗면 피어오름, 분출구, 새는 김)에 그대로 쓴다.
    띠 1장은 판정면을 채우는 본체다. 좌우 끝이 맞물리도록 x 방향으로 감아서 조립하므로
    Sprite2D의 region 반복으로 이어 붙여 무한히 흘릴 수 있다.
    """
    OUT.mkdir(parents=True, exist_ok=True)
    part = {
        key: _load_object(root, name)
        for key, name in {
            "bank": "wide_low_bank_of_steam_flat_b",
            "big": "large_billowing_steam_cloud_fi",
            "mid": "medium_billowing_steam_cloud_w",
            "ball": "dense_steam_ball_bright_white",
            "cap": "steam_mushroom_cap_wide_flat",
            "small": "small_steam_puff_made_of_two_o",
            "tiny": "tiny_single_round_ball_of_whit",
            "wave": "rolling_steam_wave_crest_curle",
            "jet": "steam_jet_burst_narrow_at_the",
        }.items()
    }

    neutral(part["small"]).save(OUT / "muneolgul_steam_puff.png")
    neutral(half(part["big"])).save(OUT / "muneolgul_steam_burst.png")
    neutral(half(part["jet"])).save(OUT / "muneolgul_steam_jet.png")
    print("  기록: muneolgul_steam_puff/burst/jet.png")

    band = Image.new("RGBA", (BAND_W, BAND_H), (0, 0, 0, 0))

    def stamp(img: Image.Image, cx: float, cy: float, alpha: int = 255, scale: float = 1.0) -> None:
        src = img
        if scale != 1.0:
            src = img.resize(
                (max(1, int(img.width * scale)), max(1, int(img.height * scale))),
                Image.Resampling.NEAREST,
            )
        if alpha < 255:
            src = src.copy()
            src.putalpha(src.getchannel("A").point(lambda v: v * alpha // 255))
        x0 = int(cx - src.width / 2)
        y0 = int(cy - src.height / 2)
        for dx in (-BAND_W, 0, BAND_W):
            layer = Image.new("RGBA", (BAND_W, BAND_H), (0, 0, 0, 0))
            layer.paste(src, (x0 + dx, y0))
            band.alpha_composite(layer)

    rng = random.Random(BAND_SEED)
    # 바닥: 빈틈 없이 메운다. 여기가 판정의 몸통이다
    for cx in range(-4, BAND_W + 12, 11):
        stamp(part["bank"], cx + rng.randint(-3, 3), BAND_H - 8 + rng.randint(-4, 4))
    for cx in range(2, BAND_W + 12, 13):
        stamp(part["ball"], cx + rng.randint(-4, 4), BAND_H - 24 + rng.randint(-5, 5), 255, 0.8)
    # 중단: 덩어리를 흩어 결을 만든다
    for cx in range(-2, BAND_W + 12, 15):
        stamp(part["mid"], cx + rng.randint(-6, 6), BAND_H - 42 + rng.randint(-7, 7), 240, 0.9)
    for cx in range(8, BAND_W + 12, 19):
        stamp(part["wave"], cx + rng.randint(-6, 6), BAND_H - 52 + rng.randint(-6, 6), 220, 0.8)
    # 상단: 높이를 크게 흔들어 윗면이 일직선이 되지 않게 한다
    tops = [BAND_H - 66, BAND_H - 78, BAND_H - 60, BAND_H - 84, BAND_H - 70, BAND_H - 90,
            BAND_H - 64, BAND_H - 80]
    for i, cx in enumerate(range(0, BAND_W + 12, 16)):
        stamp(part["big"], cx + rng.randint(-5, 5), tops[i % len(tops)] + rng.randint(-4, 4), 235, 0.95)
    for i, cx in enumerate(range(9, BAND_W + 12, 21)):
        stamp(part["cap"], cx + rng.randint(-6, 6),
              tops[(i + 3) % len(tops)] - 8 + rng.randint(-5, 5), 200, 0.85)
    # 꼭대기: 흩어져 사라지는 김. 경계가 칼로 자른 듯 끊기지 않게 한다
    for cx in range(4, BAND_W + 12, 17):
        stamp(part["small"], cx + rng.randint(-8, 8), 18 + rng.randint(-8, 6), 150, 0.9)
    for cx in range(11, BAND_W + 12, 12):
        stamp(part["tiny"], cx + rng.randint(-6, 6), 9 + rng.randint(-6, 8), 120)

    # 위로 갈수록 옅어지는 알파 경사
    alpha_px = band.getchannel("A").load()
    for y in range(BAND_H):
        k = min(1.0, 0.25 + 1.35 * (y / float(BAND_H - 1)))
        if k >= 1.0:
            continue
        for x in range(BAND_W):
            v = alpha_px[x, y]
            if v:
                alpha_px[x, y] = int(v * k)

    neutral(band).save(OUT / "muneolgul_steam_band.png")
    print(f"  기록: muneolgul_steam_band.png ({BAND_W}x{BAND_H})")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--gate", type=Path, help="대문 정면 프레임 PNG")
    ap.add_argument("--rocks", type=Path, help="낙석 4x4 시트 PNG")
    ap.add_argument("--props", type=Path, help="바람 장애물 4x4 시트 PNG")
    ap.add_argument("--steam", type=Path, help="증기 Objects ZIP 해제본의 objects 디렉터리")
    args = ap.parse_args()
    if not (args.gate or args.rocks or args.props or args.steam):
        ap.error("최소 하나는 지정해야 한다")

    if args.gate:
        print(f"대문 분할: {args.gate}")
        split_gate(args.gate)
    if args.rocks:
        print(f"낙석 분할: {args.rocks}")
        split_sheet(args.rocks, "muneolgul_rock", 4)
    if args.props:
        print(f"장애물 분할: {args.props}")
        split_sheet(args.props, "muneolgul_crate", 3)
    if args.steam:
        print(f"증기 조립: {args.steam}")
        build_steam(args.steam)


if __name__ == "__main__":
    main()
