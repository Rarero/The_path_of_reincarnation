# 에셋 요청서: act1_keyvisual

작성: 2026-07-25 (D2-1 맵과 배경 세션)
근거 문서: docs/DESIGN_ACT1.md 2장 (2.1 아트 브리프, 2.2 고증 원칙, 2.4 팔레트, 2.5 조명)
용도: 1막의 팔레트와 스타일을 고정하는 첫 산출물. ART_PIPELINE S0 스타일 정의의 입력

## 기본 정보

- 에셋 이름: act1_keyvisual
- 유형: 컨셉아트 (키비주얼)
- 최종 크기: 생성 해상도 그대로 보관 (게임 내 사용 없음, 스타일 기준용)
- 팔레트: 자유. 이 이미지에서 추출해 art_src/palettes/act1_market.gpl을 만든다
- 상태: 대기

## 생성 설정 (S1)

- 도구: PixelLab 범용 생성 (2026-07-29 외부 API 개정 반영. 구 표기는 ComfyUI 범용 모델). 팔레트 확정이 002와 003의 선행 조건이므로 조기 수행이 유리하다
- 모델: 미정 (컨셉아트는 범용 고품질 모델. ART_PIPELINE 4장)
- LoRA와 강도: 없음 (키비주얼 단계는 픽셀아트 LoRA 미적용, 구도와 색만 확정)
- 프롬프트:

```
Korean traditional night market in the underworld, side-scrolling game concept art,
a narrow market street at night lit only by hanging paper lanterns,
rows of cloth-canopy market stalls with wooden plank counters, straw mats, earthenware jars, brass bowls, strings of coins,
a sand wrestling ring with low earthen rim on one side, a low gambling table under a canopy on the other,
a small tavern stall with a boiling iron cauldron over a clay stove and a hanging liquor flag,
Joseon dynasty folk market architecture, thatched and tiled low wooden buildings, bamboo posts, plank walls,
silhouettes of dokkaebi customers in hanbok with paeraengi bamboo hats browsing in the background,
dominant warm amber and orange lantern glow against deep indigo and violet night,
warm pools of light on the ground with dark gaps between them,
one large pale moon low in the sky, distant roof ridgelines as flat indigo silhouettes,
faint teal will-o-wisp flames only in the dark side alley,
five depth layers clearly separated by value: bright detailed foreground street, dimmer mid-street, flat far silhouettes,
lively festive mood, painterly pixel-art oriented concept art, 16:9 horizontal composition
```

- 네거티브 프롬프트:

```
japanese oni, horns, tiger skin loincloth, spiked iron club, red oni mask,
japanese matsuri, japanese festival lanterns, chochin, torii, kanji, hiragana, katakana,
chinese red lanterns, chinese architecture, palace, dancheong bright polychrome,
daylight, blue sky, sunset, neon, cyberpunk, modern signage, readable text, watermark,
red dominant palette, teal dominant palette, cluttered center, character close-up
```

- 생성 해상도: 1344x768 또는 1536x864 (16:9)
- 샘플러, 스텝, CFG: DPM++ 2M Karras, 30, 6.5 (초안)
- 채택 시드: (생성 후 기록)

## 변형 프롬프트 (구간 테마별, 같은 네거티브 사용)

- 지붕 위: 위 프롬프트의 거리 묘사를 아래로 교체
  `viewed from the tiled rooftops looking down over the market, moonlit cool grey-blue roof ridges in the foreground, warm lantern glow rising from the street below, chimney smoke, quiet and open mood`
- 골목: `a narrow dark back alley between plank walls, only two or three lanterns, stacked earthenware jars, a stone well, faint teal will-o-wisp flames floating, secretive and confined mood`

## 후처리 (S2)

- 없음 (컨셉아트는 후처리 대상 아님). 팔레트 추출만 수행하고 결과를 art_src/palettes/에 저장

## 결과

- 최종 파일: art_src/generated/ 보관 (git 제외), 채택본은 별도 기록
- 메모: 채택 후 이 이미지에서 추출한 색을 docs/DESIGN_ACT1.md 2.4절 색 채널 규약의 실제 색값으로 확정한다
- 청록 도깨비불이 프롬프트에 포함된 것은 색 채널 정의 목적이다 (2.4절 예외 3건). 인게임 배경 레이어(002)에는 청록을 사용하지 않는다
