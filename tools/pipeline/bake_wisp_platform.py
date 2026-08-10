"""발판용 도깨비불 스프라이트를 굽는다.

적으로 나오는 도깨비불과 발판으로 쓰이는 도깨비불이 dokkaebi_fire.png 한 장을
공유해 구분이 안 된다는 지적을 받았다. 색은 둘 다 청록을 유지하고(청록은 도깨비불
계열 전용 채널이다) 실루엣으로 나눈다.

  적    : 얼굴이 있는 둥근 불꽃. 생물로 읽힌다
  발판  : 얼굴이 없는 납작한 원반. 윗면에 밝은 테두리를 둬 밟는 면으로 읽힌다
"""

from PIL import Image

SRC = "assets/sprites/enemies/dokkaebi_fire.png"
DST = "assets/sprites/levels/wisp_platform_fire.png"

W, H = 20, 13


def palette(path):
    """원본에서 명도 순으로 청록 팔레트를 뽑는다."""
    img = Image.open(path).convert("RGBA")
    px = img.load()
    seen = {}
    for y in range(img.height):
        for x in range(img.width):
            c = px[x, y]
            if c[3] == 0:
                continue
            lum = 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]
            # 눈처럼 아주 어두운 색은 얼굴 요소라 발판에는 쓰지 않는다
            if lum < 45:
                continue
            seen[c[:3]] = seen.get(c[:3], 0) + 1
    ordered = sorted(seen, key=lambda c: 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2])
    return ordered


def main():
    cols = palette(SRC)
    dark, mid, light = cols[0], cols[len(cols) // 2], cols[-1]
    rim = tuple(min(255, int(v * 1.0) + 40) for v in light)

    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = out.load()
    cx, cy = (W - 1) / 2.0, (H - 1) / 2.0 + 1.0
    rx, ry = (W - 1) / 2.0, 4.2

    for y in range(H):
        for x in range(W):
            d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
            if d > 1.0:
                continue
            if y <= cy - ry * 0.62:
                px[x, y] = rim + (255,)          # 윗면 테두리: 밟는 면
            elif y < cy:
                px[x, y] = light + (255,)
            elif y < cy + ry * 0.55:
                px[x, y] = mid + (255,)
            else:
                px[x, y] = dark + (255,)

    # 위로 오르는 불티 두 점. 발판이 살아 있다는 신호만 주고 얼굴은 만들지 않는다
    for x, y in ((cx - 4, 0), (cx + 5, 1)):
        px[int(x), int(y)] = light + (255,)

    out.save(DST)
    print(DST, out.size, "팔레트", dark, mid, light)


if __name__ == "__main__":
    main()
