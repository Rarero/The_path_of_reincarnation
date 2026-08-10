"""요청서 022 신당 배경 조각 베이크 (S2 후처리 전단계).

PixelLab 생성 그리드에서 채택 셀을 잘라 인게임 규격 조각으로 굽는다.
처리 순서: 셀 추출 -> 잔여 파편 제거 -> 색조 통일(선택) -> 감마 밝기 보정
          -> 접지 정렬(하단/가운데) -> 캔버스 맞춤 -> 알파 이진화
신목은 오색천이 함께 구워진 합본이라 art_src/work/act1_shrine에 먼저 굽고,
weather_ribbons_act1로 나무와 천을 나눈 뒤 천에만 바람 순환 프레임을 준다.

팔레트 강제 양자화는 하지 않는다. act1_night_draft.gpl로 양자화하면 돌무더기의
한색 화강암 색조가 팔레트의 온색 목재 계열로 끌려가 재질이 무너진다(2026-08-05 검수).
팔레트는 색 검수 기준(청록/적색 부재, 명도대)으로만 쓴다. 상세는 요청서 022 B-7.

사용:
  python3 tools/pipeline/bake_shrine_act1.py --src art_src/generated/pixellab/grids \
      --out assets/sprites/bg/act1/shrine

의존성: pip install pillow
"""

from __future__ import annotations

import argparse
import colorsys
import sys
from collections import deque
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from weather_ribbons_act1 import split_and_weather  # noqa: E402

# (그리드 파일, 셀폭, 셀높이, 채택 셀(row, col), 출력명, 목표 평균명도,
#  채도배율, 색상이동, 최종 캔버스, 하단 접지 여부, 남길 연결성분 수)
JOBS: list[dict] = [
    {
        # 서낭당 신목 v2 (2026-08-05 사용자 교정). 그냥 나무가 아니라 가지에 맨 긴
        # 오색천이 늘어진 서낭당 고유 형태다. 오색천이 조각에 함께 구워져 있다.
        # v1(act1_shrine_sinmok_64x80.png, 64x80)과 v1_rejected(160x224 민무늬)는 기록용으로 보존.
        "grid": "act1_shrine_sinmok_ribbon_160x224.png",
        "cell": (160, 224),
        "pick": (0, 0),
        "out": "bg_sinmok_composite.png",
        "work": True,
        "target": 86.0,
        "sat": 1.0,
        "hue": 0.0,
        "canvas": (160, 224),
        "ground": True,
        "keep": 1,
    },
    {
        "grid": "act1_shrine_cairn_l_32x24.png",
        "cell": (32, 24),
        "pick": (4, 3),
        "out": "bg_cairn_l.png",
        "target": 86.0,
        "sat": 1.0,
        "hue": 0.0,
        "canvas": (32, 24),
        "ground": True,
        "keep": 1,
    },
    {
        # 소 돌무더기 생성물은 온색(황토)으로 이탈해 대 돌무더기와 재질이 어긋났다.
        # 채도 -66%와 색상 이동으로 회청 화강암 색조에 맞춘다.
        "grid": "act1_shrine_cairn_s_24x16.png",
        "cell": (24, 16),
        "pick": (3, 3),
        "out": "bg_cairn_s.png",
        "target": 80.0,
        "sat": 0.34,
        "hue": 0.52,
        "canvas": (16, 14),
        "ground": True,
        "keep": 1,
    },
    {
        "grid": "act1_shrine_ohsaekcheon_48x24.png",
        "cell": (48, 24),
        "pick": (1, 1),
        "out": "bg_ohsaekcheon.png",
        "target": 86.0,
        "sat": 0.92,
        "hue": 0.0,
        "canvas": (48, 24),
        "ground": False,
        "keep": 2,
        "deredden": True,
        "moss": True,
    },
    # --- 사당 세트 (골목 사당, L3 몸주 신당) ---
    {
        "grid": "act1_shrine_hall_96x112.png",
        "cell": (96, 112),
        "pick": (1, 1),
        "out": "bg_shrine_hall.png",
        "target": 86.0,
        "sat": 1.0,
        "hue": 0.0,
        "canvas": (96, 112),
        "ground": True,
        "keep": 1,
    },
    {
        "grid": "act1_shrine_jangseung_m_24x56.png",
        "cell": (24, 56),
        "pick": (1, 1),
        "out": "bg_jangseung_m.png",
        "target": 86.0,
        "sat": 1.0,
        "hue": 0.0,
        "canvas": (24, 56),
        "ground": True,
        "keep": 1,
    },
    {
        "grid": "act1_shrine_jangseung_f_24x56.png",
        "cell": (24, 56),
        "pick": (1, 2),
        "out": "bg_jangseung_f.png",
        "target": 86.0,
        "sat": 1.0,
        "hue": 0.0,
        "canvas": (24, 56),
        "ground": True,
        "keep": 1,
    },
    {
        "grid": "act1_shrine_geumjul_96x40.png",
        "cell": (96, 40),
        "pick": (0, 0),
        "out": "bg_geumjul.png",
        "target": 86.0,
        "sat": 1.0,
        "hue": 0.0,
        "canvas": (96, 40),
        "ground": False,
        "keep": 3,
    },
    {
        # 청록 예외 대상. 감마는 색상을 바꾸지 않으므로 촛불 청록이 유지된다
        "grid": "act1_shrine_candlestand_16x24.png",
        "cell": (16, 24),
        "pick": (3, 4),
        "out": "bg_candlestand.png",
        "target": 86.0,
        "sat": 1.0,
        "hue": 0.0,
        "canvas": (16, 24),
        "ground": True,
        "keep": 1,
    },
    {
        # 무신도는 등불 아래 놓인 종이 표면이라 다른 조각보다 밝게 둔다
        "grid": "act1_shrine_musindo_32x40.png",
        "cell": (32, 40),
        "pick": (0, 0),
        "out": "bg_musindo.png",
        "target": 95.0,
        "sat": 1.0,
        "hue": 0.0,
        "canvas": (32, 40),
        "ground": False,
        "keep": 1,
    },
]

# 근경 후열(0.85) 파생 조각
FAR_VARIANTS = [("bg_cairn_s.png", "bg_cairn_s_far.png", (14, 12))]

# 신목 합본을 두는 중간 산출 폴더. 천 분리 전 단계라 인게임 에셋이 아니다
WORK_DIR = Path(__file__).resolve().parents[2] / "art_src" / "work" / "act1_shrine"

# 적색 채널은 생기 몰림 전용이라 배경에서 비운다. 오색의 적(赤) 자리는 저채도 자주로 치환
PLUM_HUE = 318.0 / 360.0
PLUM_MAX_SAT = 0.34

# 오색천 넷째 폭 녹(綠) 복원 (reference/pantheon/02_gods.md 2장: 오색 헝겊은 청 홍 백 황 녹).
# 생성물은 남색 폭이 둘이라 넷째 폭만 이끼빛 저채도 녹으로 돌린다. 색상 112도는
# 청록 도깨비불 신호대(150~200도)와 충분히 떨어져 발판 오독을 만들지 않는다.
MOSS_HUE = 112.0 / 360.0
MOSS_MAX_SAT = 0.34
MOSS_BAND_X = (27, 36)
INDIGO_HUE_RANGE = (205.0, 265.0)


def components(img: Image.Image) -> list[list[tuple[int, int]]]:
    """알파 128 이상 픽셀의 8방향 연결성분을 크기 내림차순으로 반환한다."""
    w, h = img.size
    px = img.load()
    seen = [[False] * w for _ in range(h)]
    found: list[list[tuple[int, int]]] = []
    for y in range(h):
        for x in range(w):
            if seen[y][x] or px[x, y][3] < 128:
                continue
            queue = deque([(x, y)])
            seen[y][x] = True
            cells: list[tuple[int, int]] = []
            while queue:
                cx, cy = queue.popleft()
                cells.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and px[nx, ny][3] >= 128:
                        seen[ny][nx] = True
                        queue.append((nx, ny))
            found.append(cells)
    found.sort(key=len, reverse=True)
    return found


def mean_luma(img: Image.Image) -> float:
    px = img.load()
    total = 0.0
    count = 0
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            total += 0.299 * r + 0.587 * g + 0.114 * b
            count += 1
    return total / max(1, count)


def bbox(img: Image.Image) -> tuple[int, int, int, int]:
    px = img.load()
    min_x, min_y, max_x, max_y = img.width, img.height, -1, -1
    for y in range(img.height):
        for x in range(img.width):
            if px[x, y][3] >= 128:
                min_x = min(min_x, x)
                max_x = max(max_x, x)
                min_y = min(min_y, y)
                max_y = max(max_y, y)
    return min_x, min_y, max_x, max_y


def retint(img: Image.Image, sat: float, hue: float) -> Image.Image:
    if sat == 1.0 and hue == 0.0:
        return img
    out = img.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            hh, ss, vv = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            hh = (hh + hue) % 1.0
            ss = max(0.0, min(1.0, ss * sat))
            rr, gg, bb = colorsys.hsv_to_rgb(hh, ss, vv)
            px[x, y] = (round(rr * 255), round(gg * 255), round(bb * 255), a)
    return out


def deredden(img: Image.Image) -> int:
    """적색 계열 픽셀을 저채도 자주로 치환한다 (요청서 022 B-5)."""
    px = img.load()
    changed = 0
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            hh, ss, vv = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            deg = hh * 360
            if (deg <= 20 or deg >= 345) and ss > 0.20:
                rr, gg, bb = colorsys.hsv_to_rgb(PLUM_HUE, min(ss, PLUM_MAX_SAT), vv)
                px[x, y] = (round(rr * 255), round(gg * 255), round(bb * 255), a)
                changed += 1
    return changed


def restore_moss(img: Image.Image) -> int:
    """오색천 넷째 폭의 남색을 저채도 녹으로 되돌린다 (요청서 022 B-5)."""
    px = img.load()
    changed = 0
    x0, x1 = MOSS_BAND_X
    for y in range(img.height):
        for x in range(x0, min(x1, img.width)):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            hh, ss, vv = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            deg = hh * 360
            if INDIGO_HUE_RANGE[0] <= deg <= INDIGO_HUE_RANGE[1] and ss > 0.15:
                rr, gg, bb = colorsys.hsv_to_rgb(
                    MOSS_HUE, min(ss * 0.78, MOSS_MAX_SAT), min(1.0, vv * 1.06)
                )
                px[x, y] = (round(rr * 255), round(gg * 255), round(bb * 255), a)
                changed += 1
    return changed


def gamma_to_mean(img: Image.Image, target: float) -> tuple[Image.Image, float]:
    """0과 255를 보존하는 감마로 평균 명도를 target에 맞춘다 (램프 단수 유지)."""
    lo, hi = 0.25, 3.0
    best = img
    gamma = 1.0
    for _ in range(40):
        gamma = (lo + hi) / 2
        lut = [round(255 * ((i / 255) ** gamma)) for i in range(256)]
        best = img.copy()
        px = best.load()
        for y in range(best.height):
            for x in range(best.width):
                r, g, b, a = px[x, y]
                px[x, y] = (lut[r], lut[g], lut[b], a)
        if mean_luma(best) < target:
            hi = gamma
        else:
            lo = gamma
    return best, gamma


def binarize_alpha(img: Image.Image, threshold: int = 128) -> Image.Image:
    alpha = img.getchannel("A").point(lambda v: 255 if v >= threshold else 0)
    img.putalpha(alpha)
    return img


def bake(job: dict, src_dir: Path, out_dir: Path) -> None:
    grid = Image.open(src_dir / job["grid"]).convert("RGBA")
    cw, ch = job["cell"]
    row, col = job["pick"]
    cell = grid.crop((col * cw, row * ch, (col + 1) * cw, (row + 1) * ch))

    px = cell.load()
    found = components(cell)
    for comp in found[job["keep"] :]:
        for x, y in comp:
            px[x, y] = (0, 0, 0, 0)

    cell = retint(cell, job["sat"], job["hue"])
    if job.get("deredden"):
        print(f"  적색 치환 {deredden(cell)}px")
    if job.get("moss"):
        print(f"  넷째 폭 녹 복원 {restore_moss(cell)}px")
    cell, gamma = gamma_to_mean(cell, job["target"])

    min_x, min_y, max_x, max_y = bbox(cell)
    content = cell.crop((min_x, min_y, max_x + 1, max_y + 1))

    out_w, out_h = job["canvas"]
    out = Image.new("RGBA", (out_w, out_h), (0, 0, 0, 0))
    ox = (out_w - content.width) // 2
    oy = out_h - content.height if job["ground"] else 0
    out.paste(content, (ox, oy))
    out = binarize_alpha(out)

    target_dir = WORK_DIR if job.get("work") else out_dir
    target_dir.mkdir(parents=True, exist_ok=True)
    out.save(target_dir / job["out"], "PNG")
    print(
        f"{job['grid']} r{row}c{col} -> {job['out']} {out.size} "
        f"내용 {content.size} 평균명도 {mean_luma(out):.1f} 감마 {gamma:.3f}"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="022 신당 배경 조각 베이크")
    parser.add_argument("--src", type=Path, default=Path("art_src/generated/pixellab/grids"))
    parser.add_argument("--out", type=Path, default=Path("assets/sprites/bg/act1/shrine"))
    args = parser.parse_args()

    for job in JOBS:
        bake(job, args.src, args.out)

    # 신목은 천이 함께 구워져 있다. 나무와 천을 나눠 천에만 바람 프레임을 준다
    split_and_weather(
        WORK_DIR / "bg_sinmok_composite.png",
        args.out / "bg_sinmok.png",
        args.out / "bg_sinmok_ribbon.png",
    )

    for src_name, dst_name, size in FAR_VARIANTS:
        img = Image.open(args.out / src_name).convert("RGBA")
        far = binarize_alpha(img.resize(size, Image.Resampling.NEAREST))
        far.save(args.out / dst_name, "PNG")
        print(f"{src_name} -> {dst_name} {far.size} (근경 후열 0.85 베이크)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
