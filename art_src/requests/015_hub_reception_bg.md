# 에셋 요청서: hub_reception_bg

작성: 2026-08-03 (프론트엔드 세션)
근거 문서: docs/DESIGN_HUB.md 1장, 3장, 8장, docs/ART_STYLE.md
용도: 시작 허브(저승 초입 접수청) 배경. 레이어 분리로 조립

## 기본 정보

- 에셋 이름: hub_reception_bg (레이어 세트)
- 유형: 배경 (레이어)
- 최종 크기: 320x180 기준. 허브 폭 약 480px(가로 스크롤). 지면선 앵커 y160
- 팔레트: 접수청 서브 팔레트(황혼빛 관청, 침침한 중채도). 1막 시장 난색과 구분
- 상태: 생성 완료, 임포트 대기 (2026-08-03 단일 배경 채택. 조각 세트는 후속 리파인 후보)

## 생성 설정 (S1, PixelLab)

- 도구: PixelLab 배경 생성 또는 조각 세트(1막 배경 조각 방식 준용, 요청서 008 참고)
- 고정 헤더 (ART_STYLE 9장): SCALE 16px=1m, REFERENCE Skul 톤, VIEW 정측면, PIXEL 굵은 픽셀, LIGHT 황혼 실내광
- 레이어 구성:
  - 원경: 저승 관청 청사 외곽, 위로 뻗은 상행 길과 먼 염라대전 실루엣
  - 중경: 민원창구 열, 번호표와 서류 더미, 대기줄 구조물
  - 좌측 구간: 특수창고(선반, 상자, 매달린 이름표). 사망 반송 지점
  - 근경 지면: 접수청 마룻바닥과 소품
- 프롬프트:

```
side-scrolling background of an underworld reception office at dusk (Korean jeoseung),
left area a dim storage annex with wooden shelves, boxes and hanging paper name tags,
center a row of administrative service windows with number tickets and stacked ledgers,
right side an upward path and a distant palace silhouette in the far background,
Joseon dynasty government office architecture, tiled roofs, plank floor, paper windows,
muted twilight palette faded indigo and ash grey with dim amber lantern glow, low contrast solemn,
five depth layers separated by value, painterly pixel-art oriented
```

- 네거티브 프롬프트:

```
japanese oni, black death robe, japanese shinigami, torii, kanji, hiragana, katakana,
chinese red lantern, chinese palace, bright daylight, blue sky, neon, modern signage,
readable text, watermark, red dominant palette, teal dominant palette
```

- 주요 파라미터: 레이어별 개별 생성 또는 조각 세트. 지면선 y160 정합, 미러 주기 지정
- 채택 결과 (2026-08-03): PixelLab Create S-XL image (Pro), Custom size 688x296 와이드, 배경 제거 끔. 측면 입면 단일 배경(좌 특수창고, 중앙 창구와 장부, 우 상행문과 계단, 등불). 인물 미포함. 레이어 조각 세트가 아니라 단일 배경으로 우선 적용

## 후처리 (S2)

- 야간 침전은 Godot 레이어 모듈레이트로 재현(1막 방식). 조각 원본은 플랫 유지
- 팔레트 추출로 접수청 서브 팔레트 확정

## 결과

- 최종 파일: assets/sprites/bg/hub_reception_bg.png. hub.tscn에 Backdrop(Sprite2D, z_index -100, scale 0.6977, position y -13)로 월드 배경 배치. 세로 크롭 정렬은 인게임 미세 조정 대상
- 메모: 좌측 특수창고와 우측 상행문의 시선 유도가 게임 흐름(반송 지점 좌, 1막 진입 우)과 일치해야 한다
