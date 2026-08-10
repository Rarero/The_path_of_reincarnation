"""PixelLab 원본 시트를 프로젝트 색 규칙에 맞게 손본 뒤 저장한다.

청록은 도깨비불 발판 전용 색 채널이다 (DESIGN_ACT1 2.4, ENEMIES 5.2).
적 스프라이트에 청록이 남으면 발판으로 오독되므로 난색으로 돌린다.
"""

import colorsys
import sys
from PIL import Image


def is_teal(r, g, b):
    return g > r + 25 and b > r + 25 and abs(g - b) < 55 and g > 95


def retint_teal(img):
    px = img.load()
    n = 0
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a == 0 or not is_teal(r, g, b):
                continue
            h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
            nr, ng, nb = colorsys.hls_to_rgb(0.10, l * 0.92, min(s * 0.55, 0.32))
            px[x, y] = (int(nr * 255), int(ng * 255), int(nb * 255), a)
            n += 1
    return n


def main():
    src, dst = sys.argv[1], sys.argv[2]
    im = Image.open(src).convert("RGBA")
    print(src.split("/")[-1], "청록 난색화", retint_teal(im), "px")
    im.save(dst)


if __name__ == "__main__":
    main()
