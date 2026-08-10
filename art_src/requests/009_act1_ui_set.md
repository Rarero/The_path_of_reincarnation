# 에셋 요청서: act1_ui_set (M2 UI 세트)

작성: 2026-07-30 (A1 세션)
목적: M2 수직 슬라이스가 소비할 UI 에셋. ROADMAP M2 아트 1순위
근거 문서: docs/PROTOTYPE.md (HUD 요소), docs/RUN_STRUCTURE.md 4장 (노드 맵 UI), GDD 7장 (권능 3칸 + 액티브 1칸)
스타일 앵커: 요청서 006 채택 체력바 프레임 (옻칠 나무, 황동 모서리, 회문 문양 테두리, 중채도 야경 + 난색 포인트). 이 스타일 서술을 전 UI에 동일 적용

## 공통 스타일 서술 (UI Creator Description)

```
dark lacquered wood frame with korean traditional pattern border, brass corner
fittings, muted night palette with warm orange accents, clean pixel art, black outline
```

## 목록

| # | 항목 | 도형 구성 | 상태 |
|---|---|---|---|
| 1 | HUD 세트: 체력바, 스태미나바, 슬롯 4칸(권능 3 + 액티브 1) | Health bar x2 + Icon button x4 | 대기 |
| 2 | 패널 프레임 (상점/신당/노드맵 공용 창) | Window + Tab | 대기 |
| 3 | 엽전 카운터, 탄창 표시 (소형) | Icon button + Button | 대기 |

- 규칙: UI 에셋에 글자를 굽지 않는다 (로컬라이즈는 엔진 텍스트. 장식 글자가 필요하면 도깨비 위조 글자, DESIGN_ACT1 2.2)
- 산출물은 Split into elements로 요소 분리 후 개별 다운로드 가능

## 결과

- 2026-07-30 항목 1 완료: HUD 세트 (체력바 + 스태미나바 게이지 2종, 적색 분절 채움 포함 + 슬롯 4칸). 스타일 앵커와 일치. 다운로드
  - 메모: 슬롯에 견본 아이콘(검, 방패, 물약, 열쇠)이 구워짐. 실사용은 프레임만 쓰거나 인페인트로 비움. 게이지 적색 채움은 생기 몰림 적색 신호와의 혼선 여부를 M2에서 판단 (HUD는 별개 계층이라 관용 표준이나 확인 필요)
- 2026-07-30 항목 2 완료: 패널 프레임 (Window 도형). 견본 텍스트(SYSTEM, OK/CANCEL)가 구워졌으나 9-slice 저장 (L64 R64 T64 B64) — 모서리와 테두리 밴드는 깨끗. Godot NinePatchRect에서 center fill을 끄고 내부는 어두운 단색으로 처리. 다운로드
- 항목 3 (엽전 카운터, 탄창): HUD 프레임 재활용 검토 후 필요 시 생성 (보류)
- 교훈: UI Creator의 Window/Button 도형은 견본 텍스트를 구움. 텍스트 없는 프레임이 필요하면 Panel 도형 사용 또는 9-slice 추출
