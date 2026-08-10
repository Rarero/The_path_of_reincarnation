#!/usr/bin/env python3
"""검 공격 4종을 기존 melee 클립에서 파생시킨다 (요청서 025 C-2, 사용자 확정 2026-08-07).

플레이어 몸은 AI로 다시 그리지 않는다(docs/DECISIONS.md 2026-08-07). 그래서 검
3연타와 점프 공격도 새로 생성하지 않고 이미 인게임에 있는 player_melee_e.png
(총검 찌르기 9프레임)의 몸을 재배열해 만든다. 소총은 strip_rifle.py가 이미
걷어냈으므로 입력은 player_bare_melee_e.png다.

세 타를 무엇으로 구분하는가. 몸이 같은 원본에서 나오므로 자세만으로는 구분이
약하다. 구분은 두 가지가 맡는다.

1. **무기 각도.** 환도는 오버레이라 프레임마다 각도를 따로 준다. 1타는 몸 앞을
   수평으로, 2타는 아래에서 위로, 3타는 머리 위에서 아래로 훑는다. 같은 몸
   위에서도 칼이 다른 궤도를 그린다
2. **참격 이펙트.** fx_slash_level, fx_slash_up, fx_slash_heavy가 타격 순간에
   무기를 대신한다(ART_WEAPON_SPLIT 6장 확인 1). 궤도를 읽히게 하는 것은
   실제로 이 이펙트다

프레임 선택도 다르게 잡아 무게중심을 바꾼다. 3타는 예비를 길게 가져가고
마지막에 정지 프레임을 한 장 더 붙여 마무리로 읽히게 한다.

사용법: python tools/pipeline/derive_attacks.py
입력: art_src/work/body/player_bare_melee_e.png
산출: art_src/work/body/player_bare_<공격>_e.png
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent.parent
WORK = ROOT / "art_src/work/body"
SRC = WORK / "player_bare_melee_e.png"

CANVAS = 76

## melee 원본 프레임 구성
##   0~3 서 있는 예비, 4~5 앞으로 내딛으며 찌르기, 6 최대 신전, 7~8 회수 자세
## 값은 melee 프레임 인덱스다. 프레임 수는 요청서 025 C-2 표를 따른다
SEQUENCES: dict[str, list] = {
    ## 1타 수평 베기. 예비 2장, 타격 2장, 후딜 4장
    "attack1": [2, 3, 4, 5, 6, 7, 8, 0],
    ## 2타 올려베기. 1타보다 한 장 늦게 시작해 연타로 이어지는 느낌을 준다
    "attack2": [3, 4, 5, 6, 7, 8, 0, 1],
    ## 3타 내려찍기. 예비를 길게 끌고 마지막에 정지 한 장을 더 붙인다
    "attack3": [0, 1, 2, 3, 4, 5, 6, 7, 8, 0],
    ## 점프 공격. 예비 없이 신전부터 들어간다
    "air_attack": [4, 5, 6, 7, 8, 0],
}


def main() -> int:
    if not SRC.exists():
        print("입력이 없다: %s" % SRC)
        print("먼저 python tools/pipeline/strip_rifle.py melee 를 실행한다")
        return 1
    source = Image.open(SRC).convert("RGBA")
    count = source.width // CANVAS
    frames = [source.crop((CANVAS * i, 0, CANVAS * (i + 1), CANVAS)) for i in range(count)]
    for name, sequence in SEQUENCES.items():
        out = Image.new("RGBA", (CANVAS * len(sequence), CANVAS), (0, 0, 0, 0))
        for index, pick in enumerate(sequence):
            out.alpha_composite(frames[pick], (CANVAS * index, 0))
        path = WORK / ("player_bare_%s_e.png" % name)
        out.save(path)
        print("  %-11s %2d프레임 <- melee %s" % (name, len(sequence), sequence))
    print("무기 각도와 이펙트는 previz_weapon.py의 ANCHORS에서 준다")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
