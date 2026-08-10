"""아트 파이프라인 S2 후처리 스크립트.

AI 생성 원본을 게임용 픽셀아트 규격으로 변환한다.
처리 순서: 다운스케일(최근접, 선택) -> 팔레트 양자화(선택) -> 알파 이진화(선택)

외부 API(PixelLab 등) 출력은 이미 목표 해상도의 픽셀아트이므로 --scale, --size 없이
팔레트 양자화와 알파 이진화만 적용할 수 있다. 고해상도 원본(범용 생성 모델 출력)은
--scale 또는 --size로 다운스케일한다.

사용 예:
  python3 tools/pipeline/postprocess.py in.png --scale 8 --out out.png
  python3 tools/pipeline/postprocess.py in.png --size 32x32 --out out.png \
      --palette art_src/palettes/global.gpl --alpha-threshold 128
  python3 tools/pipeline/postprocess.py pixellab_tile.png --out out.png \
      --palette art_src/palettes/global.gpl --alpha-threshold 128

의존성: pip install pillow
상세: docs/ART_PIPELINE.md 3장 S2, docs/ART_PIPELINE_SETUP.md
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image


def parse_gpl(path: Path) -> list[tuple[int, int, int]]:
    """GIMP/Aseprite 팔레트(.gpl) 파일에서 RGB 색 목록을 읽는다."""
    colors: list[tuple[int, int, int]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith(("#", "GIMP", "Name:", "Columns:")):
            continue
        parts = line.split()
        if len(parts) < 3:
            continue
        try:
            r, g, b = int(parts[0]), int(parts[1]), int(parts[2])
        except ValueError:
            continue
        colors.append((r, g, b))
    if not colors:
        raise ValueError(f"팔레트에서 색을 읽지 못함: {path}")
    if len(colors) > 256:
        raise ValueError(f"팔레트 색 수 초과(최대 256): {len(colors)}")
    return colors


def build_palette_image(colors: list[tuple[int, int, int]]) -> Image.Image:
    """quantize()에 사용할 팔레트 이미지를 만든다."""
    flat: list[int] = []
    for r, g, b in colors:
        flat.extend((r, g, b))
    # 256색까지 첫 색으로 패딩 (PIL 팔레트 규격)
    flat.extend(colors[0] * (256 - len(colors)))
    pal_img = Image.new("P", (1, 1))
    pal_img.putpalette(flat)
    return pal_img


def downscale(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    """최근접 보간으로 다운스케일한다. 픽셀 경계를 보존한다."""
    return img.resize(size, Image.Resampling.NEAREST)


def quantize_to_palette(img: Image.Image, colors: list[tuple[int, int, int]]) -> Image.Image:
    """RGB 채널을 팔레트 색으로 강제한다. 알파는 분리 보존한다."""
    alpha = img.getchannel("A")
    rgb = img.convert("RGB")
    pal_img = build_palette_image(colors)
    quantized = rgb.quantize(palette=pal_img, dither=Image.Dither.NONE)
    result = quantized.convert("RGBA")
    result.putalpha(alpha)
    return result


def binarize_alpha(img: Image.Image, threshold: int) -> Image.Image:
    """반투명 픽셀을 제거한다. threshold 미만은 완전 투명, 이상은 불투명."""
    alpha = img.getchannel("A").point(lambda a: 255 if a >= threshold else 0)
    img.putalpha(alpha)
    return img


def parse_size(value: str) -> tuple[int, int]:
    """"32x32" 형식 문자열을 (w, h)로 변환한다."""
    try:
        w_str, h_str = value.lower().split("x")
        w, h = int(w_str), int(h_str)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"크기 형식 오류(예: 32x32): {value}") from exc
    if w <= 0 or h <= 0:
        raise argparse.ArgumentTypeError(f"크기는 양수여야 함: {value}")
    return (w, h)


def main() -> int:
    parser = argparse.ArgumentParser(description="AI 생성 원본을 픽셀아트 규격으로 후처리")
    parser.add_argument("input", type=Path, help="입력 PNG 경로")
    parser.add_argument("--out", type=Path, required=True, help="출력 PNG 경로")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--scale", type=int, help="다운스케일 배율 (예: 8 이면 1/8 크기)")
    group.add_argument(
        "--size", type=parse_size, help="목표 크기 (예: 32x32). --scale, --size 모두 생략 시 크기 유지"
    )
    parser.add_argument("--palette", type=Path, help="강제할 팔레트 .gpl 파일")
    parser.add_argument(
        "--alpha-threshold",
        type=int,
        default=None,
        metavar="0-255",
        help="알파 이진화 임계값. 지정 시 반투명 픽셀 제거",
    )
    args = parser.parse_args()

    if not args.input.is_file():
        print(f"입력 파일 없음: {args.input}", file=sys.stderr)
        return 1
    if args.scale is not None and args.scale < 1:
        print(f"배율은 1 이상이어야 함: {args.scale}", file=sys.stderr)
        return 1
    if args.alpha_threshold is not None and not 0 <= args.alpha_threshold <= 255:
        print(f"알파 임계값 범위 오류(0-255): {args.alpha_threshold}", file=sys.stderr)
        return 1

    img = Image.open(args.input).convert("RGBA")

    if args.size is not None:
        img = downscale(img, args.size)
    elif args.scale is not None:
        img = downscale(img, (max(1, img.width // args.scale), max(1, img.height // args.scale)))

    if args.palette is not None:
        img = quantize_to_palette(img, parse_gpl(args.palette))

    if args.alpha_threshold is not None:
        img = binarize_alpha(img, args.alpha_threshold)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    img.save(args.out, "PNG")
    print(f"완료: {args.input} ({Image.open(args.input).size}) -> {args.out} {img.size}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
