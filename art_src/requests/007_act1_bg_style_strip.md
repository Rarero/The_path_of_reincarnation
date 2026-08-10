# 에셋 요청서: act1_bg_style_strip (배경 스타일 검증 스트립)

작성: 2026-07-30 (A1 세션, 첫 장면 생성물 기각 후 교정판)
목적: 배경의 시점, 픽셀 밀도, 도깨비 고증, 3요소 통합감을 한 장에서 검증하는 기준 스트립. 채택되면 이후 배경 조각 생성의 스타일 앵커가 된다
근거 문서: docs/ART_STYLE.md 5장(배경 제작 규칙), 9장(프롬프트 수식어), docs/DESIGN_ACT1.md 2장, reference/act1_dokkaebi/01 6장

## 기각된 1차 생성물의 문제 (2026-07-30 사용자 지적 8건 요약)

1. 45도 원근 시점 (사이드뷰 아님)
2. 미세 픽셀 일러스트풍 (원하는 굵은 픽셀 아님. 기준: ref_pixel_density_* 3장)
3. 도깨비가 오니/고블린 조형 (뿔, 초록 피부)
4. 좌판, 노름판, 씨름판이 따로 놀고 씨름꾼이 사람
5. (에셋 관점) 배경 루프 애니메이션 계획 부재
6. 등불색 처리 미결 (색 채널 규약과 사용자 요청의 충돌, DECISIONS 참고)

## 기본 정보

- 에셋 이름: act1_bg_style_strip
- 유형: 배경 (스타일 검증용. 실제 에셋은 조각 분리 생성)
- 크기: 256x144 (인게임 논리 해상도 감각. 화면 폭 640의 약 40퍼센트 스트립)
- 상태: 생성 중 (2차 채택 후보 확보)

## 생성 설정 (S1, PixelLab)

- 도구: Creator, Create S-XL image (Pro), Custom size 256x144, Remove background 해제
- 채택 프롬프트 (2026-07-30 2차):

```
flat side view 2D platformer background strip, korean joseon-era night market
run by dokkaebi spirits in the underworld, single ground line along the bottom,
from left to right: cloth-canopy market stall on bamboo poles with brass bowls
and jars, straw mat with three dokkaebi squatting and gambling with coins,
round sand ssireum wrestling ring where two dokkaebi wrestlers grapple,
hanging paper lanterns glowing warm orange, dark indigo night sky,
korean dokkaebi are human-shaped with shaggy hair and bamboo hats,
NO horns, NO oni, NO goblin, chunky pixel art, low resolution,
thick black outlines, bold simple shapes, limited palette,
no perspective, no isometric, no depth angle
```

- 2차 결과 검수 (Claude 1차 판독):
  - 시점: 측면 입면, 단일 지면선. 통과
  - 픽셀 밀도: 굵은 픽셀, 큰 색 덩어리. 레퍼런스 감각에 근접
  - 고증: 패랭이 쓴 사람 형상 도깨비, 뿔 없음. 통과. 씨름꾼도 인간형 (도깨비 정체성 표현은 캐릭터 에셋 단계에서 강화)
  - 통합감: 같은 지면선과 등불 줄로 3요소 연결
  - 잔여 이슈: 씨름꾼 샅바가 청/적색 (색 채널 규약상 배경 적색 금지. 조각 생성 시 색 교체), 원경(L1 지붕 실루엣) 부재 (스트립이 L2~L3 통합이라 의도적. 레이어 분리 생성에서 해소)
- 사용자 채택 판정: 채택 (2026-07-30). 스타일 앵커 확정
- 등불 색 확정 (2026-07-30): 청사초롱 절충. 후속 조각 프롬프트에 "lantern cloth bodies in muted blue and red silk, glow stays warm orange" 추가
- 무드 기준 추가 (2026-07-30, 사용자 레퍼런스 ref_mood_market_night.png): 2차 스트립은 구성과 고증은 통과했으나 무드가 밝고 또렷해 기준 미달로 재판정. 3차 생성 수행
- 3차 생성 (무드 버전): 레퍼런스 이미지를 콘텐츠 참조로 입력("match this mood, palette, lighting and rendering style exactly") + 프롬프트를 저대비 서정 무드로 개정 (desaturated flat shapes no outlines, dark indigo dominant, soft quiet atmosphere, moon with halo, teal wisps). 256x144
- 3차 결과 검수 (Claude 1차 판독): 남색 지배, 등불 줄 2가닥과 부드러운 빛무리, 달무리, 무아웃라인 저채도 좌판, 멍석 위 웅크린 실루엣 군상(노름판), 모래 씨름판, 원거리 청록 도깨비불. 레퍼런스 무드에 근접
- 사용자 최종 판정: 무드 채택 (2026-07-30). 이 3차 버전이 무드 앵커
- 잔여 지적: 가판대 지붕 위에 잘못 생성된 탁상형 아티팩트 2곳 (사용자 표시). 앵커는 무드 기준으로만 쓰므로 수정하지 않는다. 조각 분리 생산에서는 구조물을 개별 생성하므로 재발하지 않음
- 확장 방향: 좌우로 긴 배경은 이 장면을 늘리는 방식이 아니라 레이어 분리(하늘 고정 + 전경 조각 반복, DESIGN_ACT1 2.3)로 구현한다

## 후속 (채택 시)

- 이 스트립을 art_src/style_refs/에 스타일 앵커로 복사
- 배경 조각 분리 생성 착수: 가판대, 노름판 멍석, 씨름장, 등불 줄, L1 지붕 실루엣 밴드 (각각 요청서 신규 작성, DESIGN_ACT1 2.6 규격 준수)
- 루프 애니메이션 대상 지정: 등불 흔들림, 천막 자락, 엽전 뒤집기 (ART_STYLE 5장)

## 결과

- 원본 저장: art_src/generated/pixellab/ (다운로드 대기)
- 메모: 소모 20 generations x 2회 (1차 기각분 포함)
