#!/usr/bin/env python3
"""맨손 몸과 검 공격 클립을 인게임 에셋으로 반입한다 (docs/ART_WEAPON_SPLIT.md 5장).

art_src/work/body는 검수 자리이고 assets/sprites/player/anim이 인게임이다.
채택 판정을 받은 뒤 이 스크립트가 옮긴다. 소총 파지 원본은 지우지 않고
art_src/work/sword/rifle_ref에 남긴다. 앵커 계산(gen_weapon_anchors.py)이
원본과 맨손의 차이를 입력으로 쓰기 때문에 원본이 사라지면 앵커를 다시
구울 수 없다.

총 클립 3종(shoot, reload, reload_run)과 roll은 건드리지 않는다. 총은 아직
진입로가 없고, 들어올 때는 기준 몸에 동작 추가로 다시 굽는다(6장 확인 2).

사용법: python tools/pipeline/install_bare_body.py
"""

from __future__ import annotations

import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
WORK = ROOT / "art_src/work/body"
DEST = ROOT / "assets/sprites/player/anim"
REF = ROOT / "art_src/work/sword/rifle_ref"

## 맨손으로 갈아 끼우는 코어 클립. 이름은 그대로라 player_frames가 그대로 산다
CORE = ["idle", "run", "jump", "fall", "wall", "hurt", "melee"]

## 새로 들어오는 검 공격 클립 (derive_attacks.py 산출)
ATTACKS = ["attack1", "attack2", "attack3", "air_attack"]


def main() -> int:
    REF.mkdir(parents=True, exist_ok=True)
    moved = 0
    for clip in CORE + ATTACKS:
        src = WORK / ("player_bare_%s_e.png" % clip)
        if not src.exists():
            print("  없음 %-11s %s" % (clip, src.name))
            continue
        dest = DEST / ("player_%s_e.png" % clip)
        ## 소총 원본은 앵커 재계산에 필요하므로 덮어쓰기 전에 남긴다
        keep = REF / dest.name
        if dest.exists() and not keep.exists():
            shutil.copy2(dest, keep)
        shutil.copy2(src, dest)
        print("  %-11s -> %s" % (clip, dest.name))
        moved += 1
    print("반입 %d종. Godot을 열면 자동으로 재임포트된다" % moved)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
