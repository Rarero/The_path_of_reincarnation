# 에셋 요청서: act1_tileset_test (첫 생성 테스트)

작성: 2026-07-29 (A1 세션)
목적: PixelLab 타일 품질 관문. 채택되면 파이프라인 확정, 미달이면 Retro Diffusion 비교 (ART_PIPELINE 9장)
근거 문서: docs/ART_STYLE.md 3, 4, 9장. docs/DESIGN_ACT1.md 2장 (밤시장 테마)

## 기본 정보

- 에셋 이름: tile_market_ground_test
- 유형: 타일셋
- 최종 크기: 16x16과 32x32 비교 생성 (크기 확정이 이 테스트의 목적 중 하나)
- 팔레트: 자유 (전역 팔레트 미확정. 채택본에서 추출 예정)
- 상태: 대기

## 생성 설정 (S1, PixelLab)

- 도구: 사이드스크롤러 타일셋 (웹 UI. 홈페이지 Tutorial의 Tileset Sidescroller 영상 참고)
- 스타일 레퍼런스: art_src/style_refs/reference_shots/ref_density_skul.png (색 대비, 밀도감 참고용. 업로드 지원 시 입력)
- 프롬프트 (지면 타일, 붙여넣기용):

```
korean night market wooden plank floor, worn wood boards with straw mat patches,
warm lantern light from above, muted night palette with warm orange accents,
clean pixel art, black outline on edges, korean folklore
```

- 변형 프롬프트 (석재 지면, 두 번째 시도용):

```
old korean stone pavement, uneven flat stones with moss between,
dim night ambience with warm lantern glow, muted colors warm accents,
clean pixel art, korean folklore
```

- 주요 파라미터: 16x16으로 1회, 32x32로 1회 (같은 프롬프트). 각 3회 이상 반복해 최선본 채택
- 채택 결과: 2026-07-30 각 1회 생성 (Tier 1 구독 후, Map Workshop, Standard 모드, Sidescroller, Transition Small 25%)
  - Center Tile: dark worn wooden planks and beams, korean night market structure, muted night palette, clean pixel art
  - Top Tile: wooden plank walkway top edge with straw mat patches and small rope knots, warm lantern light, black outline
  - 32x32: 이음새 자연스러움, 짚 매트 상단과 판자 몸체 디테일 양호, 검정 아웃라인, 톤 부합. 판정 기준 4개 중 3개 통과 수준 (인게임 스케일 확인만 남음)
  - 16x16: 연결 정상이나 디테일 표현 폭이 좁다. 짚 매트 질감이 단순화됨
  - 1차 소감: 캐릭터 32x32 전제면 타일도 32가 유리해 보임. 최종 확정은 Godot 임포트 후 인게임 확인

## 확장 (2026-07-30)

- 벽 타일셋 32x32 생성 (시장 골목 벽): 프롬프트는 목골 회벽 + 석재 기단이었으나 결과는 판자벽 + 짚 갓돌 (기존 플랫폼 세트의 벽 변형 성격). 방 외곽 벽 채움으로 사용 가능. 계정 저장, 내보내기는 M2
- 잔여 타일 테마: 창고, 광장 석재 등은 방 템플릿 설계와 함께 M2에서 추가

## 판정 기준 (기록란)

- [ ] 이음새: 타일이 반복 배치될 때 경계가 자연스러운가
- [ ] 픽셀 밀도: 뭉개짐 없이 픽셀 단위가 살아 있는가
- [ ] 톤: 중채도 야경 + 난색 포인트에 부합하는가 (ART_STYLE 3장)
- [ ] 16 대 32: 어느 쪽이 인게임 스케일 감각에 맞는가 (스크린샷 배율로 가늠)
- 종합 판정: 채택 / 조건부(수작업 보정 전제) / 미달(Retro Diffusion 비교로)

## 후처리 (S2)

- 명령: python3 tools/pipeline/postprocess.py 입력.png --out 출력.png --alpha-threshold 128 (팔레트 확정 전이라 --palette 생략)

## 결과

- 원본 저장: art_src/generated/pixellab/
- 채택본 복사: art_src/style_refs/ (스타일 레퍼런스 시작점)
- 메모: (반복 횟수, 무료 등급 제약 여부, 소감)
