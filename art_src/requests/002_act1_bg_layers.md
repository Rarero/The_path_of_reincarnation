# 에셋 요청서: act1 배경 레이어 3종

작성: 2026-07-25 (D2-1 맵과 배경 세션)
근거 문서: docs/DESIGN_ACT1.md 2.3절 (레이어 구성과 스크롤 계수), 2.4절 (팔레트), 2.7절 (테마별 변조)
참고 도식: art_src/references/act1_bg_layers.svg
선행 조건: 004_act1_keyvisual 채택으로 팔레트 확정, M1에서 타일 크기와 기준 해상도 확정, 003 구조물과 tile_act1_market 확정 (근경 명도 위계를 맞추려면 근경이 먼저 있어야 한다. DESIGN_ACT1 13장 생성 순서 4번)

## 기본 정보

- 에셋 이름: bg_act1_sky (L0), bg_act1_far (L1), bg_act1_mid (L2)
- 유형: 배경 (가로 타일러블)
- 최종 크기: 기준 해상도 확정 후 산정. 화면 가로의 2배 이상 (초안: 기준 640x360이면 폭 1280 이상)
- 팔레트: art_src/palettes/act1_market.gpl (004 요청서 산출)
- 상태: 대기

## 생성 설정 (S1)

- 워크플로: 미정. 가로 타일러블 생성(seamless tiling)과 ControlNet 구도 통제 필요 (ART_PIPELINE 4장)
- 모델: 미정
- LoRA와 강도: 픽셀아트 LoRA 적용
- 프롬프트 (L0 하늘):

```
seamless horizontal tileable pixel art night sky background, deep indigo to violet gradient,
one large pale moon with soft halo, thin wispy clouds, very few dim stars,
extremely low contrast, no ground, no buildings, flat minimal detail, 16-bit era pixel art
```

- 프롬프트 (L1 원경):

```
seamless horizontal tileable pixel art distant silhouette layer, Korean traditional low village roofline,
thatched roofs and tiled roofs, gentle mountain ridgeline behind, one distant jangseung totem pole,
flat two-tone indigo silhouette only, no windows, no lights, no texture detail, 16-bit era pixel art
```

- 프롬프트 (L2 중경):

```
seamless horizontal tileable pixel art midground layer of a Korean Joseon night market street,
rows of cloth canopy stalls, strings of hanging paper lanterns with small warm amber point lights,
wooden signboards with unreadable glyphs, thin smoke from a cauldron,
silhouettes of hanbok-wearing customers with bamboo hats walking, seen from behind,
darker in value than the foreground, warm amber lights but muted overall brightness,
no walkable horizontal platforms, no ground plane, 16-bit era pixel art
```

- 네거티브 프롬프트 (3종 공통):

```
japanese oni, horns, japanese festival lanterns, chochin, torii, kanji, hiragana, katakana,
chinese red lanterns, palace architecture, dancheong, daylight, blue sky,
red dominant, teal glow, will-o-wisp, bright white highlights,
walkable platform, ledge, floor plane, player character, enemies, readable text, watermark,
high contrast foreground detail, vertical seam
```

- 생성 해상도: 1024x512 (L0, L1), 1024x384 (L2). 후처리에서 축소
- 샘플러, 스텝, CFG: DPM++ 2M Karras, 25, 7 (초안)
- 채택 시드: (생성 후 기록)

## 제약 확인 (생성물 검수 체크리스트)

- [ ] 청록과 적색이 배경에 없다 (2.4절 색 채널 규약: 도깨비불과 데스매치 전용)
- [ ] L2에 발판처럼 보이는 수평 구조물이 없다 (2.3절 시차 오브젝트 금지)
- [ ] 명도 위계가 L3 근경보다 낮다 (근경 타일셋과 나란히 놓고 확인)
- [ ] 좌우 이음새가 보이지 않는다
- [ ] 오니 계열 도상이 없다 (2.2절 고증 원칙)

## 후처리 (S2)

- 명령 (예시, 크기는 확정 후 수정):
  `python tools/pipeline/postprocess.py in.png --size 1280x360 --out out.png --palette art_src/palettes/act1_market.gpl`

## 결과

- 최종 파일: assets/sprites/bg/bg_act1_sky.png, bg_act1_far.png, bg_act1_mid.png
- 메모:
