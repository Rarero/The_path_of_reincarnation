# 에셋 요청서: 021 1막 지형 타일셋과 지형 오브젝트 (PixelLab)

작성: 2026-08-04 (맵 지형 전면 개편 후속. DECISIONS 2026-08-04)
목적: 코드 생성 플레이스홀더 타일셋(tileset_act1.png)을 PixelLab 생성물로 교체한다. 방 레이아웃과 콜리전(tileset_act1.tres)은 그대로 두고 아틀라스 그림만 바꾼다
근거 문서: docs/ROOM_SPEC.md 5장(심볼과 아틀라스 배치), docs/ART_STYLE.md 3~5장(저채도 야경, 검정 아웃라인, 디더링 금지), 요청서 005(첫 타일셋 테스트 학습)

## 기본 정보

- 도구: PixelLab Map Workshop, 사이드스크롤러 타일셋 16x16 (Standard, Transition Small 25%)
- 오브젝트: PixelLab Objects, Sidescroller view, 48px
- 상태: 생성 완료분 검수 중 (2026-08-04)

## 생성 목록과 프롬프트

### 타일셋 (Center Tile ↗ Top Tile)

1. 흙길 (G) 1차 - 기각 (남색 돌 몸체 + 고채도 주황 상단. 저채도 지시 무시됨)
   - center: dark packed earth ground with embedded small stones, korean old market street soil, muted low saturation night palette, clean pixel art
   - top: trampled dirt street surface with faint pebbles and straw bits, subtle top highlight, black outline on top edge
2. 흙길 (G) 2차 재생성 - 색 금지어 명시
   - center: plain packed dirt soil cross section, dark umber brown earth with a few gray pebbles, desaturated earthy brown tones only, no blue, no purple, no yellow, clean pixel art
   - top: flat trodden dirt road surface, slightly lighter dusty brown top line with tiny stones, desaturated, no bright colors, thin dark outline on top edge
3. 판벽 (P) - 채택 후보 (구조 양호, 상단 캡 채도는 후처리로 하향)
   - center: weathered dark wooden plank wall, vertical boards with support beams, korean old market alley, muted low saturation night palette, clean pixel art
   - top: wooden wall top cap beam, worn timber edge with subtle highlight, black outline on top edge
4. 기와 (R) - 검수 대기
   - center: dark charcoal blue korean giwa roof tiles, overlapping curved clay tile rows seen from side, muted low saturation night palette, clean pixel art
   - top: korean giwa roof ridge cap, walkable flat tile row with round end caps, faint moonlight highlight, black outline on top edge
5. 석축 (S) - 검수 대기
   - center: old korean stone wall, stacked granite blocks with dark mortar joints, muted cool gray night palette, clean pixel art
   - top: flat worn granite cap stones, subtle cool highlight, black outline on top edge

### 오브젝트 (48px, Sidescroller)

6. 좌판 (stall_cover) - 16변형 중 3종 채택 (홍백 차양 2, 녹백 차양 1)
   - korean market wooden stall stand with striped cloth awning, side view, goods on counter, muted low saturation night palette, black outline, clean pixel art, transparent background
7. 평상 (=) 원웨이 발판 원본
   - long low korean wooden bench platform pyeongsang, flat plank top with short legs, side view, muted wood tones, black outline, clean pixel art, transparent background
8. 처마 (~) 원웨이 발판 원본
   - horizontal korean giwa roof eave strip, single row of dark curved roof tiles with round end caps below, side view, muted charcoal blue, black outline, clean pixel art, transparent background

## 조립 규격 (S3)

- PixelLab 시트(64x64, 4x4)에서 표면/속/모서리/좌우 타일을 잘라 tileset_act1.png의 아틀라스 좌표(ROOM_SPEC 5장, gen_tileset_act1.py 주석)에 맞춰 재배치한다
- 기와 경사(/, \\)는 시트에 없으므로 기와 재질에서 45도 마스킹으로 파생 제작한다
- 평상/처마 오브젝트는 좌/중/우 3분할해 아틀라스 4~5행에 배치한다
- 경사, 원웨이 콜리전 정의(tileset_act1.tres)는 변경하지 않는다

## 후처리 (S2)

- 채도 하향: 전 타일 HSV 채도 약 -25~35% (배경 야간 침전과의 위계는 유지하되 고채도 캡 제거)
- 알파 이진화: --alpha-threshold 128
- 다운스케일 없음 (원본이 목표 해상도)

## 판정 기준 (기록란)

- [ ] 이음새: 반복 배치 시 경계 자연스러움
- [ ] 저채도 야경 톤 부합 (ART_STYLE 3장. 고채도 원색 캡 금지)
- [ ] 검정 아웃라인 유지 (플레이 레이어 분리 신호)
- [ ] 인게임 스케일 확인 (Godot 임포트 후)
- 종합 판정: (기입)

## 채택 결과 (2026-08-04)

원본 저장 (2026-08-05 분류 정리로 경로와 이름 개정):
- art_src/generated/pixellab/grids/ : act1_tileset_earth_16.png (흙길, 갈색 재생성본 채택),
  act1_tileset_stone_16.png (석축), act1_tileset_plank_16.png (판벽), act1_tileset_giwa_16.png (기와)
- art_src/generated/pixellab/objects/ : act1_obj_pyeongsang_48.png (평상 채택),
  act1_obj_eave_48.png (처마 채택), act1_obj_stall_48.png (좌판 홍백 채택).
  변형 후보 보존: act1_obj_pyeongsang_alt_48.png, act1_obj_eave_alt_48.png,
  act1_obj_stall_green_48.png, act1_obj_stall_red_alt_48.png

조립 (tools/pipeline/assemble_tileset_act1.py 신설):
- 각 시트에서 fill 셀 (2,1)만 추출. top(표면) 셀은 재질마다 세로기둥/가로표면이
  섞여 일관되지 않아, fill 질감에 밝은 지표선 3px + 검정 아웃라인을 얹어 표면을 만든다
- 채도 하향(흙 0.72, 석축 0.78, 판벽 0.70, 기와 0.72)으로 배경 야간 톤과 명도 위계 확보
- 코너와 좌우 가장자리는 fill/top에 검정 아웃라인을 변별로 덧대 room_terrain.gd 8열 배치에 정합
- 기와 경사(/, \\)는 giwa fill을 45도 삼각 마스크 + 사면 마루색 하이라이트로 파생
- 평상(4행)/처마(5행)는 obj_a/obj_c 상판 밴드를 16px 좌/중/우/단독 타일로 슬라이스
- 좌판 스프라이트는 obj_f 채도 하향본. stall_cover.tscn Visual position을 48px에 맞춰 -22로 조정

교체:
- assets/sprites/tiles/tileset_act1.png (코드 생성 플레이스홀더 -> PixelLab 조립본)
- assets/sprites/tiles/stall_cover.png (48x48)

- 잔여(Windows Godot): 임포트(Nearest, mipmap off) 후 인게임 톤과 이음새, 좌판 접지 확인
