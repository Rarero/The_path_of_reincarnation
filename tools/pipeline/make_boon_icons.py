#!/usr/bin/env python3
"""권능(보은) 아이콘 16x16 생성기.

산신 계열 3종과 조왕 계열 4종의 UI 아이콘을 픽셀맵에서 직접 찍어 만든다.
외부 생성 모델이나 네트워크 에셋을 쓰지 않는다.

사용법:
    python tools/pipeline/make_boon_icons.py [출력폴더]
기본 출력: assets/sprites/ui/boons/

규격 (docs/DESIGN_ACT1.md 2.4 색 채널 규약, docs/systems/BOONS.md 2장 조형 기준):
- 정확히 16x16, RGBA, 투명 배경
- 안티앨리어싱 금지. 알파는 0 또는 255만 쓴다
- 아이콘당 색 4~6종 (외곽선 포함)
- 어두운 색 1px 외곽선이 형태를 감싼다
- 내용은 14x14 안에 넣고 가장자리 1px는 비운다

색 채널 제약:
- 조왕(불)에 적색 금지. 적색은 생기 몰림 전용 신호다. 노랑~호박(색상 30~45도)만 쓴다
- 청록(색상 150~200도) 금지. 도깨비불 발판 신호 전용이다
- 산신은 흙과 돌과 뼈 (회갈색, 탁한 녹색, 뼈 흰색)
- 호랑이는 호피 무늬 금지 (DECISIONS 2026-08-06 산신 조형 배제 기준). 이빨 같은 부위 형상만 쓴다

손으로 고치는 법: ICONS의 픽셀맵은 16줄 x 16글자 문자열이다.
PALETTE의 글자를 바꿔 칠하고 마침표는 투명이다.
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_OUT_DIR = REPO_ROOT / "assets" / "sprites" / "ui" / "boons"

SIZE = 16

# 팔레트. 글자 하나가 색 하나다. 마침표(.)는 투명이며 팔레트에 없다.
PALETTE: dict[str, str] = {
    # --- 산신 계열: 흙, 돌, 뼈 ---
    "K": "#16130f",  # 외곽선 (흙빛 먹색)
    "B": "#ebe4d0",  # 뼈 밝은 면
    "b": "#b0a589",  # 뼈 그늘
    "G": "#4e3a2e",  # 잇몸 어두운 면 (적색으로 읽히지 않게 갈색으로 눕힘)
    "g": "#67503e",  # 잇몸 밝은 면
    "S": "#807767",  # 돌 밝은 면 (회갈색)
    "M": "#6b6355",  # 돌 중간 면
    "s": "#4a4339",  # 돌 그늘
    "m": "#56643a",  # 이끼 (탁한 녹색)
    # --- 조왕 계열: 불과 부엌 ---
    "k": "#1a110a",  # 외곽선 (그을음 먹색)
    "Y": "#ffd24a",  # 불꽃 밝은 노랑 (색상 45도)
    "O": "#f0912a",  # 불꽃 주황 (색상 31도)
    "E": "#a86518",  # 잉걸 깊은 호박 (색상 32도)
    "C": "#8a6c4e",  # 아궁이 흙벽 밝은 면
    "c": "#56402e",  # 아궁이 흙벽 그늘
    "H": "#3a3430",  # 숯 (탄 나무)
    "I": "#8a8e96",  # 쇠 (부지깽이)
}

# 아이콘 정의. (파일명, 읽히는 형상, 픽셀맵 16줄)
ICONS: list[tuple[str, str, list[str]]] = [
    (
        # 산의 뼈: 2초 제자리 무적. 바위에 박힌 뼈. 아래가 무겁고 정지된 인상
        "boon_sansin_san_ppyeo",
        "바위에 박힌 뼈 기둥",
        [
            "................",
            ".....KK..KK.....",
            "....KBBKKBBK....",
            "....KBBBBBBK....",
            "....KbBBBBbK....",
            ".....KBBBBK.....",
            "......KBbK......",
            "......KBbK......",
            "......KBbK......",
            "...KKKKKKKKKK...",
            "..KSmSSSSSSSSK..",
            "..KSmmSSssSSSK..",
            "..KSSSSsSSSssK..",
            "..KssSssssSssK..",
            "..KKKKKKKKKKKK..",
            "................",
        ],
    ),
    (
        # 범의 이빨: 스태미나 전소, 근접 피해 2배. 송곳니 하나. 호피 무늬 없음
        "boon_sansin_beom_ippal",
        "잇몸에 박힌 큰 송곳니 하나",
        [
            "................",
            "...KKKKKKKKKK...",
            "..KGGGGGGGGGGK..",
            "..KGgGGGGGGgGK..",
            "..KKBBBBBBBBKK..",
            "...KBBBBBBBbK...",
            "...KBBBBBBbK....",
            "...KBBBBBBbK....",
            "...KBBBBBbK.....",
            "....KBBBBbK.....",
            "....KBBBbK......",
            "....KBBbK.......",
            ".....KBbK.......",
            ".....KbK........",
            "......K.........",
            "................",
        ],
    ),
    (
        # 바위 치기: 적을 날려 벽에 부딪히게 한다. 주먹만 한 바위와 튀는 파편
        "boon_sansin_bawi_chigi",
        "튀어오르는 파편과 주먹만 한 바위",
        [
            "................",
            ".........K......",
            "........KSK.....",
            "........KSK..K..",
            ".....K...K..KSK.",
            "....KSK......K..",
            ".....K..........",
            "................",
            ".....KKKKKK.....",
            "...KKSSSSSSKK...",
            "..KSSSSSsSSSSK..",
            "..KSSMMsSSSssK..",
            "..KSMMsMSSsssK..",
            "..KKssssssssKK..",
            "....KKKKKKKK....",
            "................",
        ],
    ),
    (
        # 아궁이 지피기: 발밑에 불자리. 아궁이 아치 구멍 안의 불꽃
        "boon_jowang_agungi",
        "아치 구멍 안에서 타는 아궁이",
        [
            "................",
            "................",
            "....kkkkkkkk....",
            "..kkCCCCCCCCkk..",
            "..kCCCCCCCCCck..",
            ".kCCCCCCCCCCcck.",
            ".kCCCCkkkkCCcck.",
            ".kCCCkkkkkkCcck.",
            ".kCCCkkYYkkCcck.",
            ".kCCCkYYYYkCcck.",
            ".kCCCkOYYOkCcck.",
            ".kCcCkOYYOkCcck.",
            ".kccCkOOOOkccck.",
            ".kccckOOOOkccck.",
            ".kkkkkkkkkkkkkk.",
            "................",
        ],
    ),
    (
        # 잔불: 맞힌 적에게 화상이 남는다. 숯 위에 작게 남은 불씨 하나
        "boon_jowang_janbul",
        "숯덩이 위에 남은 작은 불씨",
        [
            "................",
            "................",
            "................",
            "................",
            "................",
            ".......k........",
            "......kYk.......",
            ".....kYYOk......",
            ".....kYYOk......",
            "....kOYYOk......",
            "....kOOOOk......",
            "..kkkkkkkkkkkk..",
            ".kHHEHHHHHEHHHk.",
            ".kHEHHHHHHHEHHk.",
            ".kkkkkkkkkkkkkk.",
            "................",
        ],
    ),
    (
        # 불티: 재장전 후 첫 명중이 화상 2스택. 튀어오르는 불티 여러 점
        "boon_jowang_bulti",
        "크기가 다른 불티 네 점이 튀어오른다",
        [
            "................",
            "................",
            "..........k.....",
            ".........kYk....",
            "..........k..k..",
            ".......kk...kYk.",
            "......kYYk...k..",
            "......kOEk......",
            ".......kk.......",
            "...kk...........",
            "..kYYk..........",
            "..kYOk..........",
            "..kOEk..........",
            "...kk...........",
            "................",
            "................",
        ],
    ),
    (
        # 부지깽이: 주기적으로 불꽃을 던진다. 끝이 달아오른 쇠 막대
        "boon_jowang_bujikkaengi",
        "끝이 달아오른 쇠 부지깽이",
        [
            "................",
            "................",
            ".kkkkkk.........",
            ".kCCCCk.........",
            ".kkkIIk.........",
            "...kkIIk........",
            "....kkIIk.......",
            ".....kkIIk......",
            "......kkIIk.....",
            ".......kkIIk....",
            "........kkEEk...",
            ".........kkOOk..",
            "..........kkYYk.",
            "...........kkkk.",
            "................",
            "................",
        ],
    ),
]


def hex_to_rgba(value: str) -> tuple[int, int, int, int]:
    """#rrggbb 를 완전 불투명 RGBA 튜플로 바꾼다."""
    raw = value.lstrip("#")
    return (int(raw[0:2], 16), int(raw[2:4], 16), int(raw[4:6], 16), 255)


def build_image(pixmap: list[str]) -> Image.Image:
    """픽셀맵 문자열을 16x16 RGBA 이미지로 찍는다. 중간 알파를 만들지 않는다."""
    if len(pixmap) != SIZE:
        raise ValueError(f"픽셀맵 줄 수가 {len(pixmap)}이다. {SIZE}이어야 한다")
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    pixels = image.load()
    for y, row in enumerate(pixmap):
        if len(row) != SIZE:
            raise ValueError(f"{y}행 길이가 {len(row)}이다. {SIZE}이어야 한다")
        for x, char in enumerate(row):
            if char == ".":
                continue
            if char not in PALETTE:
                raise ValueError(f"{y}행 {x}열의 글자 '{char}'가 팔레트에 없다")
            pixels[x, y] = hex_to_rgba(PALETTE[char])
    return image


def main(argv: list[str]) -> int:
    out_dir = Path(argv[1]).resolve() if len(argv) > 1 else DEFAULT_OUT_DIR
    out_dir.mkdir(parents=True, exist_ok=True)

    for name, reading, pixmap in ICONS:
        image = build_image(pixmap)
        path = out_dir / f"{name}.png"
        image.save(path, "PNG")
        print(f"생성: {path}  ({reading})")

    print(f"\n아이콘 {len(ICONS)}개를 {out_dir}에 썼다")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
