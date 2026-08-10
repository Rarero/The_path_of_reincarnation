#!/usr/bin/env python3
"""신당 방 2종 프리비즈. 배경 레이어까지 얹어 화면이 휑한지 판정한다.

previz_bg_act1.py와 같은 목적이되 대상이 신당 방이다. 방 씬(.tscn)의 좌표를
파싱해 조각과 라이트를 그리고, 그 뒤에 bg_act1의 고정 레이어와 신당 프리셋의
생성 요소(좌우 거리, 창 불빛, 안개, 불똥)를 근사해 깐다.

근사 범위: Godot 난수를 복제하지 않으므로 배치는 예시다. 판정 대상은 밀도와 톤이다.

사용: python3 tools/pipeline/previz_shrine_rooms.py
출력: art_src/previz/act1_shrine_rooms.png
"""

from __future__ import annotations

import pathlib
import random
import re
import sys

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[2]
BG = ROOT / "assets" / "sprites" / "bg" / "act1"
SH = BG / "shrine"
GLOW = Image.open(ROOT / "assets" / "sprites" / "fx" / "glow_radial_64.png").convert("RGBA")

VW, VH, TOP, ZOOM = 480, 270, 82, 2
WARM = (1.0, 0.745, 0.431)
VOID = (120.0, 360.0)
# 방 씬에서 가산 글로우로 쓰는 텍스처 id (ExtResource 이름)
GLOW_IDS = ("14_glow", "16_glow")
# 신당 한색 안개와 신기 티끌 (bg_act1.gd SHRINE_MIST_*, SPIRIT_MOTE_* 근사)
MIST = (0.62, 0.70, 0.92)
MOTE = (0.78, 0.84, 0.95)

TEX = {
    "10_hall": "bg_shrine_hall.png", "11_jm": "bg_jangseung_m.png", "12_jf": "bg_jangseung_f.png",
    "13_geum": "bg_geumjul.png", "14_musin": "bg_musindo.png", "15_candle": "bg_candlestand.png",
    "10_sinmok": "bg_sinmok.png", "12_cairnl": "bg_cairn_l.png", "13_cairns": "bg_cairn_s_far.png",
}


def load(path):
    return Image.open(path).convert("RGBA")


def modulate(img, mod):
    out = img.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            px[x, y] = (min(255, int(r * mod[0])), min(255, int(g * mod[1])),
                        min(255, int(b * mod[2])), a)
    return out


def light(canvas, cx, cy, col, energy, scale):
    size = max(2, int(64 * scale))
    tex = GLOW.resize((size, size), Image.BILINEAR)
    tp, cp = tex.load(), canvas.load()
    for yy in range(size):
        for xx in range(size):
            a = tp[xx, yy][3] / 255.0 * energy
            if a <= 0.003:
                continue
            tx, ty = cx - size // 2 + xx, cy - size // 2 + yy
            if not (0 <= tx < canvas.width and 0 <= ty < canvas.height):
                continue
            r, g, b, al = cp[tx, ty]
            cp[tx, ty] = (min(255, r + int(col[0] * a * 255)), min(255, g + int(col[1] * a * 255)),
                          min(255, b + int(col[2] * a * 255)), al)


def glow_sprite(canvas, cx, cy, sx, sy, mod):
    """방 씬의 가산 합성 스프라이트 (뒷광, 달빛 기둥, 지면 안개, 향 연기)."""
    w, h = max(1, int(64 * sx)), max(1, int(64 * sy))
    tex = GLOW.resize((w, h), Image.BILINEAR)
    tp, cp = tex.load(), canvas.load()
    r0, g0, b0, a0 = mod
    for yy in range(h):
        for xx in range(w):
            a = tp[xx, yy][3] / 255.0 * a0
            if a <= 0.002:
                continue
            tx, ty = cx - w // 2 + xx, cy - h // 2 + yy
            if not (0 <= tx < canvas.width and 0 <= ty < canvas.height):
                continue
            r, g, b, al = cp[tx, ty]
            cp[tx, ty] = (min(255, r + int(r0 * a * 255)), min(255, g + int(g0 * a * 255)),
                          min(255, b + int(b0 * a * 255)), al)


def parse_scene(path):
    nodes, cur = [], None
    for line in pathlib.Path(path).read_text(encoding="utf-8").splitlines():
        m = re.match(r'\[node name="(\w+)" type="(\w+)"', line)
        if m:
            cur = {"name": m.group(1), "type": m.group(2), "z": 0}
            nodes.append(cur)
            continue
        if cur is None:
            continue
        for pat, key, conv in (
            (r'position = Vector2\(([-\d.]+), ([-\d.]+)\)', "pos", None),
            (r'z_index = ([-\d]+)', "z", int),
            (r'texture = ExtResource\("([^"]+)"\)', "tex", None),
            (r'energy = ([\d.]+)', "energy", float),
            (r'texture_scale = ([\d.]+)', "tscale", float),
        ):
            m = re.match(pat, line)
            if not m:
                continue
            if key == "pos":
                cur["pos"] = (float(m.group(1)), float(m.group(2)))
            elif key == "tex":
                if m.group(1) in GLOW_IDS and cur["type"] == "Sprite2D":
                    cur["glow"] = True
                else:
                    cur["tex"] = TEX.get(m.group(1))
            else:
                cur[key] = conv(m.group(1))
        m = re.match(r'color = Color\(([\d.]+), ([\d.]+), ([\d.]+)', line)
        if m:
            cur["color"] = tuple(float(m.group(i)) for i in (1, 2, 3))
        m = re.match(r'modulate = Color\(([\d.]+), ([\d.]+), ([\d.]+), ([\d.]+)\)', line)
        if m:
            cur["mod"] = tuple(float(m.group(i)) for i in (1, 2, 3, 4))
        m = re.match(r'scale = Vector2\(([-\d.]+), ([-\d.]+)\)', line)
        if m:
            cur["scale"] = (float(m.group(1)), float(m.group(2)))
        if line.startswith("sprite_frames"):
            cur["ribbon"] = True
    return nodes


def in_void(left, right):
    return right > VOID[0] and left < VOID[1]


def render(scene, alley, seed=20260805):
    rng = random.Random(seed)
    sc = Image.new("RGBA", (VW, VH), (11, 11, 54, 255))
    # L0 하늘: 별, 달, 하늘 띠
    d = ImageDraw.Draw(sc)
    srng = random.Random(20260804)
    for _ in range(44):
        x, y = srng.uniform(0, VW), srng.uniform(-72, 210) - TOP
        if 0 <= y < VH:
            d.point((x, y), fill=(210, 210, int(srng.uniform(210, 255))))
    band = load(BG / "bg_sky_band.png")
    for x in (0, 256):
        sc.alpha_composite(band, (x, 217 - TOP))
    moon = load(BG / "bg_moon.png")
    sc.alpha_composite(moon, (240 - moon.width // 2, 132 - TOP - moon.height // 2))
    # L1 원경 스카이라인
    sl = modulate(load(BG / "bg_skyline_band.png"), (0.4, 0.36, 0.48))
    d.rectangle([0, 292 - TOP, VW, VH], fill=(27, 25, 45, 255))
    for x in (0, 256):
        sc.alpha_composite(sl, (x, 246 - TOP))
    # L1 등불 줄 (서낭당만)
    if not alley:
        lb = modulate(load(BG / "bg_lantern_band.png"), (1.1, 1.0, 0.88))
        sc.alpha_composite(lb, (0, 170 - TOP))
    # L2 중경
    mid_mod = (0.54, 0.46, 0.44)
    if not alley:
        mids = [modulate(load(BG / f"bg_stall_mid_{k}.png"), mid_mod) for k in ("a", "b", "c")]
        crowd = [modulate(load(BG / "crowd" / f"crowd_{k}.png"), mid_mod) for k in "abcdef"]
        x = 4.0
        while x < VW:
            im = mids[rng.randrange(len(mids))]
            if not in_void(x, x + im.width):
                sc.alpha_composite(im, (int(x), 312 - TOP - im.height))
                if rng.random() < 0.6:
                    c = crowd[rng.randrange(len(crowd))]
                    cx = x + rng.uniform(4, im.width - 8)
                    if not in_void(cx, cx + c.width):
                        sc.alpha_composite(c, (int(cx), 310 - TOP - c.height))
            x += rng.uniform(52, 82)
    # L3 근경: 방 씬 조각
    nodes = parse_scene(scene)
    drawn = [n for n in nodes if n.get("tex") or n.get("ribbon") or n.get("glow")]
    floor_done = False
    for n in sorted(drawn, key=lambda n: n["z"]):
        if not floor_done and n["z"] >= 1:
            d.rectangle([0, 336 - TOP, VW, VH], fill=(38, 32, 27, 255))
            floor_done = True
        x, y = n["pos"]
        if n.get("glow"):
            sx, sy = n.get("scale", (1.0, 1.0))
            glow_sprite(sc, int(x), int(y) - TOP, sx, sy, n.get("mod", (1.0, 1.0, 1.0, 1.0)))
            continue
        if n.get("ribbon"):
            im = load(SH / "bg_sinmok_ribbon.png").crop((0, 0, 160, 224))
        else:
            im = load(SH / n["tex"])
        sc.alpha_composite(im, (int(x), int(y) - TOP))
    if not floor_done:
        d.rectangle([0, 336 - TOP, VW, VH], fill=(38, 32, 27, 255))
    # 광원: 배경(등불 줄 / 창 불빛 / 거리 등불) + 방 라이트
    if alley:
        for i in range(5):
            wx = VW * (i + 0.5) / 5 + rng.uniform(-28, 28)
            light(sc, int(wx), int(310 - TOP - rng.uniform(18, 46)), WARM, rng.uniform(0.16, 0.26),
                  rng.uniform(0.45, 0.7))
    else:
        for lx, ly in ((36, 200), (115, 191), (196, 205), (283, 193), (365, 201),
                       (438, 190), (52, 246), (150, 250), (330, 248), (430, 244)):
            if not in_void(lx, lx):
                light(sc, lx, ly - TOP, WARM, 0.65, 1.4)
        sx = rng.uniform(24, 80)
        while sx < VW:
            if not in_void(sx, sx):
                light(sc, int(sx), 300 - TOP, WARM, rng.uniform(0.42, 0.58), rng.uniform(0.85, 1.05))
            sx += rng.uniform(80, 112)
    for n in nodes:
        if n["type"] != "PointLight2D":
            continue
        x, y = n["pos"]
        light(sc, int(x), int(y) - TOP, n["color"], n["energy"], n.get("tscale", 1.0))
    # 대기: 난색 훈기(거리)는 서낭당만, 한색 바닥 안개와 신기 티끌은 두 방 모두
    if not alley:
        for i in range(4):
            light(sc, int(VW * (i + 0.5) / 4), 300 - TOP, (1.0, 0.62, 0.33), 0.10, 4.0)
    for i in range(5):
        mx = VW * (i + 0.5) / 5 + rng.uniform(-24, 24)
        glow_sprite(sc, int(mx), 326 - TOP, rng.uniform(4.0, 6.0), rng.uniform(0.5, 0.8),
                    MIST + (0.09,))
    for _ in range(7):
        mx, my = rng.uniform(128, 352), rng.uniform(174, 336)
        glow_sprite(sc, int(mx), int(my) - TOP, 0.04, 0.04, MOTE + (rng.uniform(0.4, 0.7),))
    d.rectangle([420, 340 - TOP - 28, 431, 340 - TOP], fill=(190, 182, 176, 255))
    return sc


def render_ab(scene, alley):
    """신비감 보강 요소만 끈 화면과 켠 화면을 함께 돌려준다.

    이 요소들은 알파 0.1 안팎이라 단독 렌더로는 강도를 판정할 수 없다.
    반드시 나란히 놓고 봐야 과한지 모자란지가 보인다 (2026-08-06 검수).
    """
    on = render(scene, alley).convert("RGB")
    globals_ref = globals()
    keep_glow, keep_light = globals_ref["glow_sprite"], globals_ref["light"]

    def no_glow(*args, **kwargs):
        return None

    def no_spirit(canvas, cx, cy, col, energy, scale):
        if col == MIST:
            return
        keep_light(canvas, cx, cy, col, energy, scale)

    globals_ref["glow_sprite"], globals_ref["light"] = no_glow, no_spirit
    off = render(scene, alley).convert("RGB")
    globals_ref["glow_sprite"], globals_ref["light"] = keep_glow, keep_light
    return off, on


def compose(shots, path, columns=1):
    pad, lbl = 8, 16
    cw, ch = VW * ZOOM, VH * ZOOM
    rows = len(shots)
    out = Image.new(
        "RGB", (cw * columns + pad * (columns + 1), rows * (ch + lbl + pad) + pad), (24, 24, 30)
    )
    dr = ImageDraw.Draw(out)
    for i, row in enumerate(shots):
        y = pad + i * (ch + lbl + pad) + lbl
        for c, (name, img) in enumerate(row):
            x = pad + c * (cw + pad)
            out.paste(img.convert("RGB").resize((cw, ch), Image.NEAREST), (x, y))
            dr.text((x, y - lbl + 3), name, fill=(226, 226, 232))
    out.save(path)
    print(f"wrote {path} {out.size}")


def main() -> int:
    out_dir = ROOT / "art_src" / "previz"
    out_dir.mkdir(parents=True, exist_ok=True)
    if "--ab" in sys.argv:
        rows = []
        for name, scene, alley in (
            ("L3 alley", "room_shrine_alley.tscn", True),
            ("L7 seonangdang", "room_shrine_seonang.tscn", False),
        ):
            off, on = render_ab(ROOT / "scenes" / "levels" / scene, alley)
            rows.append([(f"{name} before", off), (f"{name} after", on)])
        compose(rows, out_dir / "act1_shrine_mystic_ab.png", columns=2)
        return 0
    shots = [
        ("L3 alley shrine", render(ROOT / "scenes/levels/room_shrine_alley.tscn", True)),
        ("L7 seonangdang", render(ROOT / "scenes/levels/room_shrine_seonang.tscn", False)),
    ]
    pad, lbl = 8, 16
    cw, ch = VW * ZOOM, VH * ZOOM
    out = Image.new("RGB", (cw + 2 * pad, len(shots) * (ch + lbl + pad) + pad), (24, 24, 30))
    dr = ImageDraw.Draw(out)
    for i, (name, img) in enumerate(shots):
        y = pad + i * (ch + lbl + pad) + lbl
        out.paste(img.convert("RGB").resize((cw, ch), Image.NEAREST), (pad, y))
        dr.text((pad, y - lbl + 3), name, fill=(226, 226, 232))
    path = out_dir / "act1_shrine_rooms.png"
    out.save(path)
    print(f"wrote {path} {out.size}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
