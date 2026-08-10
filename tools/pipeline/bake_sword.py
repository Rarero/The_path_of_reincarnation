#!/usr/bin/env python3
"""플레이어 검(환도) 클립 인게임 굽기 (요청서 025).

PixelLab Characters v3 export(64x64, East)의 프레임을 기존 플레이어 규격
(76x76 캔버스, 가로 중심 40, 발밑 57)에 맞춰 가로 스트립으로 만든다.

정렬 방식이 중요하다. 프레임마다 bbox 중심으로 다시 놓으면 검이 뻗을 때
몸이 따라 움직인다. 그래서 64x64 프레임을 통째로 76x76 한가운데(6, 6)에
붙이기만 한다. 기존 총 세트가 같은 캐릭터의 같은 캔버스에서 나왔으므로
이 방식이 두 세트의 발 기준선과 몸 중심을 자동으로 일치시킨다
(013 "64x64 원본 프레임 그대로 스트립, 프레임 간 앵커 흔들림 방지").

사용법:
    python tools/pipeline/bake_sword.py <풀린 export 폴더> [클립 ...]

클립을 생략하면 CLIPS 전체를 굽는다. 폴더 이름은 PixelLab이 애니메이션
이름에서 만든 것이라 CLIPS의 match 문자열로 부분 일치 검색한다.

산출: assets/sprites/player/anim/player_sword_<클립>_e.png
     그리고 각 프레임의 칼끝 도달 거리(몸 중심 40 기준)를 출력한다.
     이 값이 D8 히트박스 오프셋을 정하는 근거다 (요청서 025 F-5).
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent.parent
OUT_DIR = ROOT / "assets/sprites/player/anim"

## 기존 플레이어/적 스프라이트와 같은 캔버스와 기준점
CANVAS: int = 76
SOURCE: int = 64
## 64x64를 76x76 한가운데 놓는 고정 오프셋
PAD: int = (CANVAS - SOURCE) // 2
## 캔버스 안 몸 중심 x (player_frames.tres, dokkaebi_frames.tres 공통)
BODY_CENTER_X: int = 40
## 알파 이진화 문턱. 반투명 가장자리를 없앤다 (ART_STYLE 후처리 규칙)
ALPHA_CUT: int = 128

## 클립 정의. match는 export 폴더 이름의 부분 문자열, keep은 채택 프레임 인덱스.
## keep이 None이면 전체를 쓴다. 프레임 수 근거는 요청서 025 C-2.
CLIPS: dict[str, dict] = {
    "attack1": {"match": "diagonal downward", "keep": None},
    "attack2": {"match": "rising sword", "keep": None},
    "attack3": {"match": "finishing overhead", "keep": None},
    "air_attack": {"match": "airborne downward", "keep": None},
    "idle": {"match": "standing still holding", "keep": None},
    "run": {"match": "running forward holding", "keep": None},
    "jump": {"match": "jumping upward", "keep": None},
    "fall": {"match": "falling downward", "keep": None},
    "wall": {"match": "clinging to a wall", "keep": None},
    "hurt": {"match": "recoiling backward", "keep": None},
}


def binarize(image: Image.Image) -> Image.Image:
    red, green, blue, alpha = image.split()
    alpha = alpha.point(lambda value: 255 if value >= ALPHA_CUT else 0)
    return Image.merge("RGBA", (red, green, blue, alpha))


def place(source: Image.Image) -> Image.Image:
    if source.size != (SOURCE, SOURCE):
        raise SystemExit("원본이 %dx%d가 아니다: %s" % (SOURCE, SOURCE, source.size))
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    canvas.alpha_composite(source, (PAD, PAD))
    return canvas


def find_east_frames(root: Path, needle: str) -> list[Path]:
    """export 폴더에서 needle을 이름에 포함하는 애니메이션의 east 프레임을 찾는다."""
    hits: list[Path] = []
    for path in sorted(root.rglob("east")):
        if not path.is_dir():
            continue
        name = path.parent.name.replace("_", " ").lower()
        if needle.lower() in name:
            hits.append(path)
    if not hits:
        return []
    frames = sorted(hits[0].glob("frame_*.png"))
    return frames


def blade_reach(frame: Image.Image) -> int:
    """몸 중심(x=40)에서 오른쪽으로 가장 멀리 뻗은 픽셀까지의 거리."""
    box = frame.getbbox()
    if box is None:
        return 0
    return box[2] - BODY_CENTER_X


def bake(clip: str, export_root: Path) -> bool:
    spec = CLIPS[clip]
    frames = find_east_frames(export_root, spec["match"])
    if not frames:
        print("  건너뜀 %-11s (원본 없음: %r)" % (clip, spec["match"]))
        return False
    keep = spec["keep"]
    if keep is not None:
        frames = [frames[i] for i in keep if i < len(frames)]
    baked = [place(binarize(Image.open(f).convert("RGBA"))) for f in frames]
    strip = Image.new("RGBA", (CANVAS * len(baked), CANVAS), (0, 0, 0, 0))
    for index, image in enumerate(baked):
        strip.alpha_composite(image, (CANVAS * index, 0))
    out = OUT_DIR / ("player_sword_%s_e.png" % clip)
    out.parent.mkdir(parents=True, exist_ok=True)
    strip.save(out)
    reaches = [blade_reach(image) for image in baked]
    print("  %-11s %d프레임 -> %s" % (clip, len(baked), out.name))
    print("    칼끝 도달(px, 몸 중심 40 기준): %s  최대 %d"
          % (" ".join("%d" % r for r in reaches), max(reaches)))
    return True


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    export_root = Path(sys.argv[1])
    if not export_root.is_dir():
        print("폴더가 아니다: %s" % export_root)
        return 1
    wanted = sys.argv[2:] or list(CLIPS)
    unknown = [name for name in wanted if name not in CLIPS]
    if unknown:
        print("모르는 클립: %s" % ", ".join(unknown))
        return 1
    print("굽기 시작: %s" % export_root)
    done = 0
    for clip in wanted:
        if bake(clip, export_root):
            done += 1
    print("완료 %d/%d" % (done, len(wanted)))
    print("히트박스 참고: D8 초안 34x28. 칼끝 최대 도달보다 오른쪽 끝이 2px 넘게")
    print("             나가지 않도록 오프셋을 잡는다 (요청서 025 F-5)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
