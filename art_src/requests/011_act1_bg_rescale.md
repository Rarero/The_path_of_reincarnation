# 에셋 요청서: act1_bg_rescale (근경 5종 스케일 규약 재생성)

작성: 2026-08-02 (A1 세션)
목적: 크기 개연성 붕괴와 시점 불일치 교정 (DECISIONS 2026-08-02). 기존 근경 5종을 스케일 규약(16px = 1m) 크기와 통일 측면 시점으로 재생성해 교체
근거 문서: docs/ART_STYLE.md 5장 스케일 규약, 9장 고정 프롬프트 카드

## 공통 생성 설정

- 도구: Create S-XL image (Pro), 단일 실행 + 페이지 대기
- reference image 1: act1_mood_anchor.png (배경 카테고리 앵커)
- Remove background 체크 (투명 배경)
- 고정 카드 사용. CATEGORY(배경). VIEW에 저앙각 통일 추가: "flat side view, very low angle, single horizontal ground line"
- 인물 굽기 금지: SUBJECT에 "no people, no figures, empty" 명기
- 밝기 기준: 채택된 씨름판/노름판 평균 명도 132. 생성 후 미달 시 후처리 보정

## 목록과 크기 (스케일 규약 환산)

| # | 조각 | 실물 크기 | 캔버스 | 상태 |
|---|---|---|---|---|
| 1 | 가판대 (과실 좌판) | 3m | 56x48 | 대기 |
| 2 | 주막 (국밥집 건물) | 4.5m | 96x72 | 대기 |
| 3 | 귀문 | 6m | 80x96 | 대기 |
| 4 | 씨름판 (모래판 지름 8m, 측면) | 8m | 128x32 | 대기 |
| 5 | 노름판 멍석 (측면 얇은 띠) | 2m | 64x32 생성 후 32x16 정수 다운스케일 | 대기 |

## SUBJECT 서술

1. 가판대: `korean market fruit stall, wooden posts and counter, sagging cloth awning roof, baskets of fruit, no people, no figures`
2. 주막: `korean traditional tavern building, tiled roof, wooden walls, open front with hanging cauldron hearth, cloth banner, no people, no figures, empty`
3. 귀문: `towering korean spirit gate, two thick wooden pillars, heavy tiled roof beam, faded talisman papers, imposing, no people, no figures`
4. 씨름판: `wide korean ssireum sand wrestling pit seen from the side, low mound of pale sand, straw rope boundary ring, empty, no people, no figures`
5. 노름판: `thin straw mat lying flat on the ground seen from the side, scattered brass coins, low profile strip, no people, no figures`

## 판정 기준

- [ ] 플레이어 28px 대비 크기 개연성 (주막과 귀문은 플레이어를 압도해야 한다)
- [ ] 측면 저앙각 통일 (내려다본 기울기 금지)
- [ ] 인물 없음
- [ ] 무드 앵커 팔레트 일치, 명도 132 내외
- [ ] 글로우, 아웃라인 없음

## 결과

- 2026-08-02 5종 생성과 다운로드 완료 (S-XL Pro, 단일 실행, 앵커 레퍼런스):
  - 가판대 56x48: 16변형. 측면 뷰, 무인, 팔레트 일치. 1차 시도는 "no people, no figures" 부정 지시가 역효과로 인물 16종 생성 (기각, 20 gens 소모). "empty unattended ... building structure"로 교정해 성공
  - 주막 96x72: 4변형. 기와지붕 건물 형태, 걸린 국솥, 현수막. 통과 수준
  - 귀문 80x96: 4변형. 기둥 2개 + 기와 보, 부적. 위압감 있는 세로 실루엣
  - 씨름판 128x56: 4변형. 측면 낮은 모래 둔덕 + 새끼줄. 시점 통일 성공
  - 노름판 64x32: 16변형. 측면 얇은 멍석 + 엽전. 일부 하단 변형은 배경이 어두워 선별 필요
- 교훈: 부정 지시("no people")는 S-XL Pro에서 역효과. 긍정 서술("empty unattended")로 대체한다. 고정 카드 SUBJECT 작성 규칙에 반영
- 잔여: 사용자 파일 이동 (다운로드 폴더 → art_src/generated/pixellab/), 셀 선별, 다운스케일(노름판 64x32 -> 32x16), 밝기 기준(132) 확인, bg_act1.tscn 교체
