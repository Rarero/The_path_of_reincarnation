#!/usr/bin/env python3
"""1막 배경 조명/밀도 프리비즈 (Godot 없이 화면 인상을 판정하기 위한 근사 렌더).

목적: Cowork 샌드박스에서는 Godot 런타임을 실행할 수 없다. 레이어 모듈레이트,
Light2D 값, 군상 밀도를 바꿀 때마다 에디터를 열지 않고 화면 인상을 먼저 본다.

근사 범위 (실제 렌더와 다른 점):
- 조각과 군상 배치는 bg_act1.gd의 궁합 점수 배치를 그대로 재현하지 않는다.
  Godot PCG32 난수를 복제하지 않았기 때문이다. 배치는 예시이고 판정 대상은
  톤, 밝기, 밀도 감각이다
- Light2D는 "빛이 그려진 캔버스 아이템 위에만 얹힌다"는 성질만 재현한다
- 등불 흔들림과 불똥 이동은 정지 상태로 그린다
- 패럴랙스 미러링이 스프라이트만 복제하고 광원은 복제하지 않는 성질은 재현한다

출력: art_src/previz/act1_bg_light_compare.png
  좌 = 이전(2026-08-06 스크린샷 상태), 우 = 수정본. 행 = 카메라 x 2종.
  이전 열의 구세대 등불 줄은 에셋이 남아 있을 때만 그린다 (기각 후 이동됨).

사용: python tools/pipeline/previz_bg_act1.py [--seed N]
"""

from __future__ import annotations

import argparse
import pathlib
import random

import numpy as np
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[2]
BG = ROOT / "assets" / "sprites" / "bg" / "act1"
GLOW_PATH = ROOT / "assets" / "sprites" / "fx" / "glow_radial_64.png"
OLD_STRING = ROOT / "art_src" / "generated" / "pixellab" / "_to_delete" / "bg_lantern_string.png"
OUT = ROOT / "art_src" / "previz" / "act1_bg_light_compare.png"

SCREEN_W = 480
SCREEN_H = 270
CAM_TOP = 80
ZOOM = 2
CAM_XS = (0, 440)
CANVAS_TOP = -80
CANVAS_H = 520

WARM = (1.0, 0.745, 0.431)
POOL_COLOR = (1.0, 0.784, 0.51)
HAZE_COLOR = (1.0, 0.62, 0.33)
FIRE_COLOR = (0.353, 0.863, 0.784)
MOON_COLOR = (0.941, 0.941, 0.863)
CLOUD_COLOR = (0.145, 0.141, 0.298)
RIDGE_BACK = (0.118, 0.110, 0.204)
RIDGE_FRONT = (0.086, 0.078, 0.149)
EMBER_COLOR = (1.0, 0.678, 0.353)
RIDGE_BOTTOM = 298
RIDGE_HEIGHT = 104

MID_PROPS = (
    ("stall_mid_a", "bg_stall_mid_a.png", 312),
    ("stall_mid_b", "bg_stall_mid_b.png", 312),
    ("stall_mid_c", "bg_stall_mid_c.png", 312),
    ("tavern_mid", "bg_tavern_mid.png", 312),
)
NEAR_PROPS = (
    ("gate", "bg_gwimun_gate.png", 326),
    ("tavern", "bg_tavern.png", 328),
    ("stall_fruit", "bg_stall_fruit.png", 330),
    ("ring", "bg_ssireum_ring.png", 332),
    ("mat", "bg_gambling_mat.png", 332),
)
CROWD_FRONT = tuple(f"crowd/crowd_{c}.png" for c in "acdefgh")
CROWD_BACK = ("crowd/crowd_b.png",) + tuple(f"crowd/crowd_back_{c}.png" for c in "abcde")
CROWD_CHEER = ("crowd/crowd_cheer_a.png", "crowd/crowd_cheer_b.png")
CROWD_WRESTLER = ("crowd/crowd_g.png", "crowd/crowd_h.png")
CROWD_EXTRA = ("crowd/crowd_child.png", "crowd/crowd_cat.png")
LANTERN_POS = (
    (36, 280), (115, 271), (166, 284), (253, 277), (315, 275),
    (359, 284), (417, 283), (487, 272), (548, 280), (627, 271),
)

## 이전 = 2026-08-06 인게임 스크린샷 상태 (병렬 세션의 보라 침전 + 구세대 등불 줄 + 저밀도)
BEFORE = {
    "label": "before  2026-08-06 screenshot state",
    "sky_fill": (0.043, 0.043, 0.212),
    "l1_mod": (0.40, 0.36, 0.48),
    "lantern_mod": (1.10, 1.00, 0.88),
    "l2_mod": (0.42, 0.38, 0.50),
    "l3_mod": (0.60, 0.55, 0.64),
    "lantern_energy": 0.65,
    "lantern_scale": 1.4,
    "glow_mid": 0.6,
    "glow_near": 0.75,
    "mid_count": 8,
    "near_count": 7,
    "mid_crowd": 7,
    "near_crowd": 12,
    "strings": True,
    "street_lights": False,
    "activity": False,
    "back_mix": False,
}
## 수정본 = bg_act1.gd, bg_act1.tscn 2026-08-06 값
AFTER = {
    "label": "after  bright market + activities",
    "sky_fill": (0.043, 0.043, 0.212),
    "l1_mod": (0.40, 0.36, 0.48),
    "lantern_mod": (1.10, 1.00, 0.88),
    "l2_mod": (0.62, 0.53, 0.47),
    "l3_mod": (0.80, 0.71, 0.60),
    "lantern_energy": 0.65,
    "lantern_scale": 1.4,
    "glow_mid": 0.9,
    "glow_near": 1.0,
    "mid_count": 10,
    "near_count": 9,
    "mid_crowd": 9,
    "near_crowd": 11,
    "strings": False,
    "street_lights": True,
    "activity": True,
    "back_mix": True,
}


def load(name: str) -> np.ndarray:
    return np.asarray(Image.open(BG / name).convert("RGBA"), dtype=np.float32) / 255.0


def glow_tex(scale_x: float, scale_y: float) -> np.ndarray:
    img = Image.open(GLOW_PATH).convert("RGBA")
    w = max(1, int(round(img.width * scale_x)))
    h = max(1, int(round(img.height * scale_y)))
    return np.asarray(img.resize((w, h), Image.BILINEAR), dtype=np.float32) / 255.0


class Layer:
    def __init__(self, motion_scale: float, mirror: int, mod: tuple[float, float, float]):
        self.motion_scale = motion_scale
        self.mirror = mirror
        self.mod = np.array(mod, dtype=np.float32)
        self.rgb = np.zeros((CANVAS_H, mirror, 3), dtype=np.float32)
        self.alpha = np.zeros((CANVAS_H, mirror), dtype=np.float32)
        self.lights: list[dict] = []

    def _slice(self, x: int, y: int, w: int, h: int):
        y -= CANVAS_TOP
        x0, x1 = max(0, x), min(self.mirror, x + w)
        y0, y1 = max(0, y), min(CANVAS_H, y + h)
        if x0 >= x1 or y0 >= y1:
            return None
        return (slice(y0, y1), slice(x0, x1)), (slice(y0 - y, y1 - y), slice(x0 - x, x1 - x))

    def blit(self, src: np.ndarray, x: int, y: int, flip: bool = False) -> None:
        if flip:
            src = src[:, ::-1]
        cut = self._slice(x, y, src.shape[1], src.shape[0])
        if cut is None:
            return
        dst_s, src_s = cut
        s = src[src_s]
        a = s[..., 3:4]
        self.rgb[dst_s] = s[..., :3] * a + self.rgb[dst_s] * (1.0 - a)
        self.alpha[dst_s] = np.maximum(self.alpha[dst_s], s[..., 3])

    def add(self, src: np.ndarray, cx: int, cy: int, color: tuple, alpha: float) -> None:
        h, w = src.shape[:2]
        x, y = cx - w // 2, cy - h // 2
        cut = self._slice(x, y, w, h)
        if cut is None:
            return
        dst_s, src_s = cut
        s = src[src_s]
        contrib = s[..., :3] * s[..., 3:4] * np.array(color, dtype=np.float32) * alpha
        self.rgb[dst_s] = self.rgb[dst_s] + contrib
        self.alpha[dst_s] = np.maximum(self.alpha[dst_s], s[..., 3] * alpha)

    def modulated(self) -> np.ndarray:
        return self.rgb * self.mod


def blend_soft(layer, tex, cx, cy, color, alpha) -> None:
    h, w = tex.shape[:2]
    x, y = cx - w // 2, cy - h // 2
    cut = layer._slice(x, y, w, h)
    if cut is None:
        return
    dst_s, src_s = cut
    s = tex[src_s]
    a = s[..., 3:4] * alpha
    layer.rgb[dst_s] = np.array(color, dtype=np.float32) * a + layer.rgb[dst_s] * (1.0 - a)
    layer.alpha[dst_s] = np.maximum(layer.alpha[dst_s], a[..., 0])


def draw_ridge(layer, base_y, amplitude, phase, waves, color) -> None:
    width = layer.mirror
    step = 2.0 * np.pi * waves / width
    xs = np.arange(width, dtype=np.float32) * step
    wave = (np.sin(xs + phase) * 0.6 + np.sin(xs * 2.0 + phase * 1.7) * 0.28
            + np.sin(xs * 5.0 + phase) * 0.12)
    tops = (RIDGE_BOTTOM - RIDGE_HEIGHT + (base_y - wave * amplitude)).astype(int)
    for x in range(width):
        y0 = max(0, tops[x] - CANVAS_TOP)
        y1 = RIDGE_BOTTOM - CANVAS_TOP
        if y0 >= y1:
            continue
        layer.rgb[y0:y1, x] = np.array(color, dtype=np.float32)
        layer.alpha[y0:y1, x] = 1.0


def pick(rng: random.Random, pool) -> np.ndarray:
    return load(pool[rng.randrange(len(pool))])


def pick_crowd(rng: random.Random, cfg) -> np.ndarray:
    if not cfg["back_mix"]:
        return pick(rng, CROWD_FRONT)
    roll = rng.random()
    if roll < 0.1:
        return pick(rng, CROWD_EXTRA)
    if roll < 0.38:
        return pick(rng, CROWD_BACK)
    return pick(rng, CROWD_FRONT)


def put_figure(layer, img, x, bottom, flip) -> None:
    layer.blit(img, int(x), int(bottom - img.shape[0]), flip)


def place_props(layer, pool, rng, count, gap, cfg, chance, energy, gscale):
    """조각을 흩고 (이름, x, 폭, 높이, 바닥) 목록을 돌려준다."""
    x = rng.uniform(0, 40)
    anchors = []
    for _ in range(count):
        name, file, bottom = pool[rng.randrange(len(pool))]
        img = load(file)
        if x + img.shape[1] > layer.mirror:
            break
        layer.blit(img, int(x), int(bottom - img.shape[0]))
        anchors.append((name, x, img.shape[1], img.shape[0], bottom))
        x += img.shape[1] + gap + rng.uniform(12, 64)
    for name, ax, aw, ah, ab in anchors:
        if rng.random() >= chance:
            continue
        layer.lights.append(
            {
                "pos": (ax + aw * rng.uniform(0.3, 0.7), ab - ah * rng.uniform(0.55, 0.8)),
                "color": WARM,
                "energy": energy,
                "scale": (gscale, gscale),
            }
        )
    return anchors


def spawn_activities(layer, anchors, rng) -> None:
    """씨름 대전, 노름판, 좌판 손님 (bg_act1.gd _spawn_activities 근사)."""
    mats = 0
    for name, ax, aw, ah, ab in anchors:
        if name == "ring":
            wl = load(CROWD_WRESTLER[0])
            wr = load(CROWD_WRESTLER[1])
            cx = ax + aw * 0.5
            put_figure(layer, wl, cx - wl.shape[1] + 4, ab - 3, False)
            put_figure(layer, wr, cx - 2, ab - 3, True)
            for i in range(rng.randint(2, 3)):
                tex = pick(rng, CROWD_CHEER)
                left = i % 2 == 0
                wx = ax - 14 - rng.uniform(0, 8) if left else ax + aw + rng.uniform(0, 8)
                put_figure(layer, tex, wx, ab, not left)
            put_figure(layer, pick(rng, CROWD_BACK), cx + rng.uniform(-16, 10), ab + 3,
                       rng.random() < 0.5)
        elif name == "mat" and mats < 2:
            mats += 1
            for fx in (ax + aw * rng.uniform(0.05, 0.2), ax + aw * rng.uniform(0.55, 0.7)):
                put_figure(layer, pick(rng, CROWD_BACK), fx, ab + 2, rng.random() < 0.5)
            put_figure(layer, pick(rng, CROWD_FRONT), ax + aw * rng.uniform(0.3, 0.5), ab - 3,
                       rng.random() < 0.5)
            if rng.random() < 0.5:
                put_figure(layer, pick(rng, CROWD_CHEER), ax + aw + rng.uniform(2, 10), ab, True)
        elif name in ("tavern", "stall_fruit"):
            if rng.random() < 0.25:
                continue
            sx = ax + aw * rng.uniform(0.25, 0.6)
            put_figure(layer, pick(rng, CROWD_BACK), sx, ab + 1, rng.random() < 0.5)
            if rng.random() < 0.35:
                put_figure(layer, pick(rng, CROWD_BACK), sx + rng.uniform(14, 22), ab + 1,
                           rng.random() < 0.5)


def build_layers(cfg: dict, rng: random.Random) -> list[Layer]:
    sky = Layer(0.05, 512, (1.0, 1.0, 1.0))
    fill = np.ones((302, 512, 4), dtype=np.float32)
    fill[..., :3] = np.array(cfg["sky_fill"], dtype=np.float32)
    sky.blit(fill, 0, -80)
    star_rng = random.Random(20260804)
    for _ in range(44):
        px = np.ones((1, 1, 4), dtype=np.float32)
        px[..., :3] = np.array([1.0, 1.0, star_rng.uniform(0.82, 1.0)], dtype=np.float32)
        px[..., 3] = star_rng.uniform(0.35, 0.9)
        sky.blit(px, int(star_rng.uniform(0, 512)), int(star_rng.uniform(-72, 210)))
    cloud_rng = random.Random(20260805)
    for _ in range(13):
        cx = cloud_rng.uniform(0, 512)
        cy = cloud_rng.uniform(-44, 205)
        alpha = cloud_rng.uniform(0.35, 0.62)
        for pi in range(cloud_rng.randint(2, 4)):
            tex = glow_tex(cloud_rng.uniform(1.3, 2.4), cloud_rng.uniform(0.34, 0.6))
            blend_soft(sky, tex, int(cx + pi * cloud_rng.uniform(20, 46)),
                       int(cy + cloud_rng.uniform(-6, 6)), CLOUD_COLOR,
                       alpha * cloud_rng.uniform(0.6, 1.0))
    band = load("bg_sky_band.png")
    sky.blit(band, 0, 217)
    sky.blit(band, 256, 217)
    moon = load("bg_moon.png")
    sky.blit(moon, 240 - moon.shape[1] // 2, 132 - moon.shape[0] // 2)
    sky.lights.append({"pos": (240, 132), "color": MOON_COLOR, "energy": 0.3, "scale": (1.5, 1.5)})

    ridge = Layer(0.12, 512, (1.0, 1.0, 1.0))
    draw_ridge(ridge, 58.0, 16.0, 0.7, 3.0, RIDGE_BACK)
    draw_ridge(ridge, 78.0, 11.0, 2.4, 5.0, RIDGE_FRONT)

    skyline = Layer(0.2, 512, cfg["l1_mod"])
    horizon = np.ones((128, 512, 4), dtype=np.float32)
    horizon[..., :3] = np.array([0.106, 0.098, 0.176], dtype=np.float32)
    skyline.blit(horizon, 0, 292)
    sl = load("bg_skyline_band.png")[0:46, 0:256]
    skyline.blit(sl, 0, 246)
    skyline.blit(sl, 256, 246)

    lantern = Layer(0.2, 512, cfg["lantern_mod"])
    lantern.blit(load("bg_lantern_band.png"), 0, 170)
    for lx, ly in LANTERN_POS:
        lantern.lights.append(
            {
                "pos": (lx, ly - 80),
                "color": WARM,
                "energy": cfg["lantern_energy"],
                "scale": (cfg["lantern_scale"], cfg["lantern_scale"]),
            }
        )

    mid = Layer(0.55, 1024, cfg["l2_mod"])
    far = load("bg_street_band_far.png")
    mid.blit(far, 0, 302)
    mid.blit(far, 512, 302)
    mid_anchors = place_props(mid, MID_PROPS, rng, cfg["mid_count"], 8, cfg,
                              cfg["glow_mid"], 0.52, 1.1)
    if cfg["activity"]:
        for name, ax, aw, ah, ab in mid_anchors:
            if rng.random() < 0.4:
                continue
            put_figure(mid, pick(rng, CROWD_BACK), ax + aw * rng.uniform(0.25, 0.65), ab + 1,
                       rng.random() < 0.5)
    if cfg["strings"] and OLD_STRING.exists():
        strings = np.asarray(Image.open(OLD_STRING).convert("RGBA"), dtype=np.float32) / 255.0
        step = 1024 / 5
        for i in range(5):
            sx = int(step * i + rng.uniform(0, max(0.0, step - strings.shape[1])))
            sy = int(250 + rng.uniform(-6, 6))
            mid.blit(strings, sx, sy)
            mid.lights.append({"pos": (sx + strings.shape[1] * 0.5, sy + strings.shape[0] * 0.7),
                               "color": WARM, "energy": 0.35, "scale": (1.0, 1.0)})
    for _ in range(10):
        px = np.ones((1, 1, 4), dtype=np.float32)
        mid.add(px, int(rng.uniform(0, 1024)), int(rng.uniform(200, 336)), EMBER_COLOR,
                rng.uniform(0.35, 0.8) * 0.7)
    for i in range(4):
        hx = int(1024 / 4 * (i + 0.5) + rng.uniform(-20, 20))
        mid.add(glow_tex(rng.uniform(4.5, 6.5), rng.uniform(1.3, 1.9)), hx,
                int(300 + rng.uniform(-8, 8)), HAZE_COLOR, 0.07)
    for _ in range(cfg["mid_crowd"]):
        img = pick_crowd(rng, cfg)
        put_figure(mid, img, rng.uniform(0, 1024 - img.shape[1]), 310, rng.random() < 0.5)

    near = Layer(0.85, 1024, cfg["l3_mod"])
    street = load("bg_street_band.png")
    near.blit(street, 0, 316)
    near.blit(street, 512, 316)
    near_anchors = place_props(near, NEAR_PROPS, rng, cfg["near_count"], 12, cfg,
                               cfg["glow_near"], 0.66, 1.2)
    if cfg["activity"]:
        spawn_activities(near, near_anchors, rng)
    for _ in range(cfg["near_crowd"]):
        img = pick_crowd(rng, cfg)
        put_figure(near, img, rng.uniform(0, 1024 - img.shape[1]), 332, rng.random() < 0.5)
    if cfg["street_lights"]:
        x = rng.uniform(24, 80)
        while x < 1024:
            tex = glow_tex(rng.uniform(1.6, 2.4), rng.uniform(0.34, 0.5))
            near.add(tex, int(x), 331, POOL_COLOR, rng.uniform(0.26, 0.42))
            near.lights.append(
                {
                    "pos": (x, 300 + rng.uniform(-4, 4)),
                    "color": WARM,
                    "energy": rng.uniform(0.42, 0.58),
                    "scale": (rng.uniform(0.85, 1.05),) * 2,
                }
            )
            x += rng.uniform(80, 112)
    else:
        x = rng.uniform(8, 64)
        while x < 1024:
            tex = glow_tex(rng.uniform(1.6, 2.4), rng.uniform(0.34, 0.5))
            near.add(tex, int(x), 331, POOL_COLOR, rng.uniform(0.26, 0.42))
            x += rng.uniform(64, 96)
    for _ in range(3):
        near.lights.append(
            {
                "pos": (rng.uniform(24, 1000), 310 + rng.uniform(-4, 2)),
                "color": FIRE_COLOR,
                "energy": 0.45,
                "scale": (1.2, 1.2),
            }
        )
    for _ in range(14):
        px = np.ones((1, 1, 4), dtype=np.float32)
        near.add(px, int(rng.uniform(0, 1024)), int(rng.uniform(200, 336)), EMBER_COLOR,
                 rng.uniform(0.35, 0.8))

    return [sky, ridge, skyline, lantern, mid, near]


def render(cfg: dict, cam_x: int, seed: int) -> Image.Image:
    rng = random.Random(seed)
    layers = build_layers(cfg, rng)
    screen = np.zeros((SCREEN_H, SCREEN_W, 3), dtype=np.float32)
    cover = np.zeros((SCREEN_H, SCREEN_W), dtype=np.float32)
    light = np.zeros((SCREEN_H, SCREEN_W, 3), dtype=np.float32)

    for layer in layers:
        rgb = layer.modulated()
        off = -cam_x * layer.motion_scale
        for rep in (-1, 0, 1, 2):
            paste_layer(screen, cover, rgb, layer.alpha, int(round(off + rep * layer.mirror)))
        for item in layer.lights:
            lx, ly = item["pos"]
            tex = glow_tex(*item["scale"])
            add_light(light, tex, int(lx + off), int(ly - CAM_TOP), item["color"], item["energy"])

    lit = screen + light * cover[..., None]
    return Image.fromarray((np.clip(lit, 0.0, 1.0) * 255.0).astype(np.uint8), "RGB")


def paste_layer(screen, cover, rgb, alpha, sx) -> None:
    y0 = CAM_TOP - CANVAS_TOP
    src_rows = slice(y0, y0 + SCREEN_H)
    if src_rows.start < 0 or src_rows.stop > rgb.shape[0]:
        return
    w = rgb.shape[1]
    dx0, dx1 = max(0, sx), min(SCREEN_W, sx + w)
    if dx0 >= dx1:
        return
    src = rgb[src_rows, dx0 - sx : dx1 - sx]
    a = alpha[src_rows, dx0 - sx : dx1 - sx][..., None]
    screen[:, dx0:dx1] = src * a + screen[:, dx0:dx1] * (1.0 - a)
    cover[:, dx0:dx1] = np.maximum(cover[:, dx0:dx1], a[..., 0])


def add_light(light, tex, cx, cy, color, energy) -> None:
    h, w = tex.shape[:2]
    x, y = cx - w // 2, cy - h // 2
    dx0, dx1 = max(0, x), min(SCREEN_W, x + w)
    dy0, dy1 = max(0, y), min(SCREEN_H, y + h)
    if dx0 >= dx1 or dy0 >= dy1:
        return
    s = tex[dy0 - y : dy1 - y, dx0 - x : dx1 - x]
    light[dy0:dy1, dx0:dx1] += s[..., :3] * s[..., 3:4] * np.array(color, dtype=np.float32) * energy


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--seed", type=int, default=20260806)
    args = ap.parse_args()

    rows = [[render(BEFORE, cam, args.seed), render(AFTER, cam, args.seed)] for cam in CAM_XS]

    pad, lbl = 8, 16
    cw, ch = SCREEN_W * ZOOM, SCREEN_H * ZOOM
    out = Image.new("RGB", (2 * cw + 3 * pad, len(rows) * (ch + lbl + pad) + pad), (26, 26, 32))
    draw = ImageDraw.Draw(out)
    for r, row in enumerate(rows):
        for c, img in enumerate(row):
            x = pad + c * (cw + pad)
            y = pad + r * (ch + lbl + pad) + lbl
            out.paste(img.resize((cw, ch), Image.NEAREST), (x, y))
            label = (BEFORE if c == 0 else AFTER)["label"]
            draw.text((x, y - lbl + 3), f"{label}   cam_x={CAM_XS[r]}", fill=(226, 226, 232))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    out.save(OUT)
    print(f"wrote {OUT} {out.size}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
