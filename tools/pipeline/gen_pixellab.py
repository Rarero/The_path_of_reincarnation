#!/usr/bin/env python3
"""PixelLab REST 생성기 (요청서 028 프롬프트 카드용).

용도: 웹 UI를 거치지 않고 요청서의 고정 프롬프트로 캐릭터를 생성한다.
docs/ART_PIPELINE_SETUP.md 5장의 API 경로를 쓴다. pixellab 파이썬 패키지가
설치되지 않는 환경에서도 돌도록 REST를 직접 호출한다.

준비:
  1. https://www.pixellab.ai/account 에서 키 발급
  2. 저장소 루트에 .env 생성 (.env.example 복사). PIXELLAB_SECRET=발급받은_토큰
     .env는 .gitignore 대상이라 커밋되지 않는다

사용:
  python tools/pipeline/gen_pixellab.py --list
  python tools/pipeline/gen_pixellab.py egg
  python tools/pipeline/gen_pixellab.py egg porter thief

출력: art_src/generated/pixellab/chars/<이름>_v1.png
      이어서 tools/pipeline/bake_enemy_placeholders.py 방식으로 굽는다

과금 주의: API는 종량 과금이며 구독과 별도다 (ART_PIPELINE.md 6장).
한 번 호출당 1장이 생성되므로 프롬프트를 확정한 뒤 부른다.
"""

from __future__ import annotations

import argparse
import base64
import json
import pathlib
import sys
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
ENV = ROOT / ".env"
OUT_DIR = ROOT / "art_src" / "generated" / "pixellab" / "chars"
ENDPOINT = "https://api.pixellab.ai/v2/create-image-pixflux"

## 공통 수식어 (요청서 019 B, 028 B). 모든 프롬프트 앞에 붙는다
COMMON = (
    "flat side view for a 2D platformer, no perspective, no isometric, "
    "chunky pixel art, low resolution, limited palette, flat shading, "
    "unlit, no glow, no halo, no baked lighting, "
    "muted low-saturation palette, soft low-contrast shading, dark colored outline"
)

## 요청서 028 D의 프롬프트 카드. 이름 -> (설명, 폭, 높이)
JOBS: dict[str, tuple[str, int, int]] = {
    "egg": (
        "korean dalgyal-dokkaebi the egg goblin, a perfectly smooth featureless "
        "egg-shaped body standing upright, dusky indigo-violet purple color, "
        "NOT pale, NOT pink, NOT white, faint warm ochre mottled patches on the shell, "
        "no eyes no nose no mouth, no ears, no arms, no legs, no bumps, no cracks, "
        "completely smooth surface, korean folklore spirit, "
        "NO horns, NO oni, NO goblin face, NO ghost, NO sheet",
        52,
        52,
    ),
    "porter": (
        "korean dokkaebi market porter, thickset burly build, muted dusky "
        "indigo-violet skin, wild shaggy hair, plain dark hanbok work clothes, "
        "carrying a huge bundled load on a wooden A-frame carrier jige on the back, "
        "the load is a big earthenware jar and stacked firewood held with straw rope, "
        "the load turned to the front side as a shield, leaning forward under the weight, "
        "korean not japanese, NO horns, NO oni, NO kimono, NO samurai",
        88,
        88,
    ),
    "thief": (
        "korean dokkaebi fence and pickpocket, skinny wiry quick build, muted dusky "
        "indigo-violet skin, wild shaggy hair, dark ragged hanbok tucked for running, "
        "a fat cloth bundle bojagi knotted on the back full of stolen goods, "
        "one hand reaching out with grabbing fingers, crouched sneaking posture, "
        "korean not japanese, NO horns, NO oni, NO kimono, NO samurai",
        76,
        76,
    ),
}


def read_secret() -> str:
    if not ENV.exists():
        sys.exit(
            "%s 가 없다. .env.example 을 복사해 .env 를 만들고 PIXELLAB_SECRET 을 넣어라"
            % ENV
        )
    for line in ENV.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        if key.strip() == "PIXELLAB_SECRET":
            token = value.strip().strip('"').strip("'")
            if not token or token.startswith("여기에"):
                sys.exit(".env 의 PIXELLAB_SECRET 이 예시값 그대로다")
            return token
    sys.exit(".env 에 PIXELLAB_SECRET 항목이 없다")


def generate(name: str, token: str) -> pathlib.Path:
    description, width, height = JOBS[name]
    payload: dict = {
        "description": "%s, %s" % (description, COMMON),
        "image_size": {"width": width, "height": height},
        "no_background": True,
    }
    request = urllib.request.Request(
        ENDPOINT,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": "Bearer %s" % token,
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=180) as response:
            body = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", "replace")[:400]
        sys.exit("HTTP %d: %s" % (error.code, detail))
    image = body.get("image", {})
    raw = image.get("base64") or image.get("data")
    if not raw:
        sys.exit("응답에 이미지가 없다: %s" % json.dumps(body)[:300])
    if "," in raw[:64] and raw.strip().startswith("data:"):
        raw = raw.split(",", 1)[1]
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out = OUT_DIR / ("act1_%s_v1.png" % name)
    out.write_bytes(base64.b64decode(raw))
    usage = body.get("usage", {})
    print("%s -> %s  (%dx%d, usage=%s)" % (name, out, width, height, usage))
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description="요청서 028 프롬프트로 PixelLab 생성")
    parser.add_argument("names", nargs="*", help="생성할 이름 (egg porter thief)")
    parser.add_argument("--list", action="store_true", help="사용 가능한 이름 출력")
    args = parser.parse_args()
    if args.list or not args.names:
        for key, (_, width, height) in JOBS.items():
            print("%-8s %dx%d" % (key, width, height))
        return
    unknown = [n for n in args.names if n not in JOBS]
    if unknown:
        sys.exit("모르는 이름: %s" % ", ".join(unknown))
    token = read_secret()
    for name in args.names:
        generate(name, token)


if __name__ == "__main__":
    main()
