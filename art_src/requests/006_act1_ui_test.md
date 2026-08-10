# 에셋 요청서: act1_ui_test (첫 생성 테스트)

작성: 2026-07-29 (A1 세션)
목적: PixelLab UI 품질 관문. M2 소비처 1순위(UI) 검증
근거 문서: docs/ART_STYLE.md 3, 9장

## 기본 정보

- 에셋 이름: ui_health_bar_test
- 유형: UI
- 최종 크기: 인게임 HUD 기준 가로 64~96px 수준 (생성은 크게 뽑고 후처리 다운스케일 가능)
- 팔레트: 자유 (채택본에서 추출 예정)
- 상태: 대기

## 생성 설정 (S1, PixelLab)

- 도구: Create UI elements (웹 UI)
- 스타일 레퍼런스: 005 채택본이 있으면 함께 입력 (스타일 통일 확인 겸용)
- 프롬프트 (체력바, 붙여넣기용):

```
game health bar frame, dark lacquered wood with korean traditional pattern border,
brass corner fittings, empty gauge inside, muted night palette warm accents,
clean pixel art, black outline
```

- 변형 프롬프트 (엽전 카운터 아이콘, 두 번째 시도용):

```
korean brass coin icon with square hole, game currency icon,
warm metallic glint, clean pixel art, black outline, 24x24
```

- 주요 파라미터: 각 3회 이상 반복해 최선본 채택
- 채택 결과: 2026-07-30 1회 생성 (UI Creator, Health bar 160x16 도형 + 위 프롬프트, 출력 256x256, 20 generations 소모). 변형 2종 출력. 옻칠 나무 + 황동 모서리 + 회문 계열 문양이 프롬프트대로 재현. 픽셀 클린, 디더링 없음, 중채도 야경 톤 부합. 9-slice와 요소 분리 기능 확인. 다운로드와 최종 채택 판단은 보류 (무료 일일 한도 소진으로 추가 반복은 다음 날 또는 구독 후)

## 판정 기준 (기록란)

- [ ] 가독성: HUD 크기로 줄였을 때 형태가 읽히는가
- [ ] 장식 밀도: 한국 전통 문양이 과하지 않게 들어가는가
- [ ] 톤: 게임 화면(어두운 배경) 위에서 분리되는가
- 종합 판정: 채택 / 조건부 / 미달

## 후처리 (S2)

- 명령: python3 tools/pipeline/postprocess.py 입력.png --size 96x24 --out 출력.png --alpha-threshold 128 (크기는 생성물에 맞춰 조정)

## 결과

- 원본 저장: art_src/generated/pixellab/
- 메모: (반복 횟수, 소감)
