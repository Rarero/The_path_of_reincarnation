# 에셋 요청서: act1 4대 배경 구조물

작성: 2026-07-25 (D2-1 맵과 배경 세션)
근거 문서: docs/DESIGN_ACT1.md 2.6절 (구조물 스펙), 3.4절 (배치 규칙), 11장 (템플릿별 사용)
참고 도식: art_src/references/act1_structures.svg (측면 입면과 타일 격자 비율)
원본 스케치: 사용자 제공 (2026-07-25, 가판대/씨름장/노름판/식당)
선행 조건: 타일 크기 확정(M1), tile_act1_market 타일셋 선행 제작 (지형 가독성 기준 확보 후)

## 기본 정보

- 에셋 이름: prop_act1_stall, prop_act1_wrestling_ring, prop_act1_gambling_table, prop_act1_tavern
- 유형: 오브젝트 (측면 입면 스프라이트. 파괴 가능 오브젝트는 파괴 단계 프레임 포함)
- 최종 크기 (타일 16px 가정. 32px 확정 시 2배)
  - prop_act1_stall: 96x64 (6x4타일. 폭 4~6, 높이 4) + 변형 3종 + 파괴 3프레임
  - prop_act1_wrestling_ring: 256x64 (16x4타일) + 축소 변형 192x64 (12x4타일, 내기방용) + 깃대 분리 파츠
  - prop_act1_gambling_table: 128x64 (8x4타일) + 항아리 분리 파츠 3
  - prop_act1_tavern: 160x80 (10x5타일) + 국솥 애니메이션 2프레임 + 화덕 광원
- 팔레트: art_src/palettes/act1_market.gpl
- 상태: 대기

## 공통 요구사항

- 측면(사이드뷰) 입면. 원근 없음. 게임플레이 판독이 최우선
- 발판 가능 요소(진열대, 평상)와 밟을 수 없는 요소(천막 지붕, 처마)를 실루엣으로 구분한다. 지붕은 처지고 얇게, 발판은 두껍고 수평으로 그린다
- 상호작용 요소(국솥, 상금 함, 판돈)만 밝은 아웃라인. 장식은 아웃라인을 배경 명도에 묶는다
- 광원(등불, 화덕)은 본체와 분리한 별도 레이어로 내보낸다. 생기 몰림 적색 전환과 조명 제어를 위해 필요하다 (docs/DESIGN_ACT1.md 2.5절, 8장 이벤트방 요구사항)
- 글자는 도깨비 문자풍 위조 글자. 실제 문자로 읽히지 않게 한다

## 생성 설정 (S1)

- 워크플로: 미정. 오브젝트 단품은 투명 배경 생성 + 알파 이진화
- 모델: 미정 / LoRA: 픽셀아트 LoRA 적용
- 프롬프트 (prop_act1_stall 가판대):

```
pixel art side view sprite of a Korean Joseon market stall, isolated object on transparent background,
four bamboo posts holding a sagging cloth canopy, wooden plank display counter in two tiers,
goods on the counter: woven baskets of fruit, brass bowls, a pile of old farm tools,
one small paper lantern hanging from the canopy edge, warm amber lit, deep indigo shadows,
flat side elevation, no perspective, crisp outline, 16-bit era pixel art
```

- 프롬프트 (prop_act1_wrestling_ring 씨름장):

```
pixel art side view of a Korean traditional ssireum wrestling ring, isolated object on transparent background,
shallow circular sand pit rimmed by a low earthen step, sand surface slightly dished in the center,
two wooden flag poles with plain cloth banners at both ends, a small prize chest at the rim,
warm amber lit from above, flat side elevation, no perspective, 16-bit era pixel art
```

- 프롬프트 (prop_act1_gambling_table 노름판):

```
pixel art side view of a Korean folk gambling stand, isolated object on transparent background,
cloth canopy on two posts, straw mat on the ground, a very low wooden table,
piles of brass coins and traditional playing cards on the table, three earthenware jars for a shell game,
one hanging lantern, warm amber lit, flat side elevation, no perspective, 16-bit era pixel art
```

- 프롬프트 (prop_act1_tavern 주막):

```
pixel art side view of a Korean Joseon roadside tavern stall, isolated object on transparent background,
thatched roof over an open front, wooden posts, a raised wooden platform bench with a low tray table and brass bowls,
a clay stove with a large iron cauldron of boiling soup at the front, liquor jars, a hanging cloth liquor flag,
two paper lanterns under the eaves, warm amber and firelight, flat side elevation, no perspective, 16-bit era pixel art
```

- 네거티브 프롬프트 (공통):

```
japanese oni, horns, tiger skin, spiked club, japanese festival stall, yatai, chochin, torii, noren,
kanji, hiragana, katakana, chinese architecture, chinese red lanterns, palace, dancheong,
perspective view, three quarter view, isometric, top down, background scenery, ground plane, characters, people,
readable text, watermark, red dominant, teal glow, daylight, drop shadow on background
```

- 생성 해상도: 768x768 (오브젝트당). 후처리에서 규격 축소
- 샘플러, 스텝, CFG: DPM++ 2M Karras, 25, 7 (초안)
- 채택 시드: (생성 후 기록)

## 제약 확인 (생성물 검수 체크리스트)

- [ ] 발판 가능 요소와 밟을 수 없는 요소가 실루엣으로 구분된다
- [ ] 청록과 적색이 없다 (색 채널 규약)
- [ ] 타일 격자에 정렬된다 (발판 높이가 정확히 1타일)
- [ ] 광원이 분리 레이어로 존재한다
- [ ] 오니 계열, 일본 축제 계열 도상이 없다
- [ ] 플레이어 실루엣(참조 도식의 기준 크기)과 나란히 놓아도 구조물이 지형으로 읽힌다

## 후처리 (S2)

- 명령 (예시):
  `python tools/pipeline/postprocess.py in.png --size 96x64 --out out.png --palette art_src/palettes/act1_market.gpl --alpha-threshold 128`

## S3 수작업 마감 항목

- 파괴 가능 오브젝트(가판대, 짐수레, 항아리)의 파괴 프레임 3단계
- 국솥 끓는 애니메이션 2프레임, 등불 흔들림 2~3프레임 순환
- 타일 격자 정렬 보정과 발판 히트박스 기준선 표시

## 결과

- 최종 파일: assets/sprites/props/prop_act1_stall.png 등
- 메모:
