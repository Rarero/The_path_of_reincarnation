# 에셋 요청서: hub_npc_set

작성: 2026-08-03 (프론트엔드 세션)
근거 문서: docs/DESIGN_HUB.md 4장, docs/GDD.md 8장, docs/ART_STYLE.md, reference/act1_dokkaebi
용도: 허브 NPC 5인 스프라이트. 접수청에 배치

## 기본 정보

- 에셋 이름: npc_chasa, npc_seogi, npc_jumo, npc_sapsal, npc_blacksmith
- 유형: 캐릭터 (NPC)
- 최종 크기: 캐릭터 규격 준수(32x32 우선, ART_STYLE 2장). 관복 인물은 세로 여유 검토
- 팔레트: 접수청 서브 팔레트 기준. 차사만 홍철릭 적색 포인트
- 상태: 대기

## 생성 설정 (S1, PixelLab)

- 도구: PixelLab 캐릭터 생성(저장 캐릭터 ID 재사용). 차사는 오프닝 저승사자와 동일 인물이라 오프닝 컷과 디자인 공유
- 고정 헤더 (ART_STYLE 9장): SCALE 16px=1m, REFERENCE Skul 2~3등신 SD, VIEW 측면, PIXEL 검정 아웃라인, LIGHT 접수청 실내광
- NPC별 SUBJECT:
  - npc_chasa (실수한 차사): 화려한 관복의 저승사자. 홍철릭, 전립, 패영. 검은 도포 금지. 오프닝과 동일 인물. 죄책감 어린 표정
  - npc_seogi (늙은 서기 혼): 낡은 유생 복장의 늙은 서기 혼, 두루마리 명부와 붓, 반투명 혼 느낌
  - npc_jumo (주모): 저고리 치마 차림의 주모, 국자와 소반, 넉넉한 인상
  - npc_sapsal (삽살개): 삽살개, 텁수룩한 털, 마스코트 비례
  - npc_blacksmith (대장장이 도깨비): 도깨비 대장장이. reference/act1_dokkaebi 고증(뿔과 호피 금지, 더벅머리 또는 패랭이, 한복, 생산 도구로서의 방망이나 망치)
- 프롬프트 골격:

```
2 to 3 head tall SD pixel-art character, thick black outline, side view, clean shading,
[NPC SUBJECT],
Korean folk afterlife setting, muted twilight office palette, strong readable silhouette
```

- 차사 고증 지시:

```
red official robe (hongcheollik), black wide-brim official hat (jeonrip) with tassel and sash,
NOT a black hooded death robe, NOT japanese shinigami, NOT grim reaper
```

- 도깨비 고증 지시 (대장장이):

```
Korean dokkaebi, human-like folk figure, shaggy hair or paeraengi bamboo hat, hanbok,
holds a smith hammer or gnarled club as a tool,
NOT japanese oni, NO horns, NO tiger-skin, NO spiked iron club, NO solid red or blue skin
```

- 네거티브 프롬프트:

```
japanese oni, horns, tiger skin, spiked club, red oni mask, black death robe, grim reaper,
japanese shinigami, kanji, hiragana, katakana, photorealistic, 3d render, watermark
```

- 주요 파라미터: idle 우선. 필요 시 대화 반응 프레임. 저장 캐릭터 ID 기록
- 채택 결과: (생성 후 기록)

## 후처리 (S2)

- 명령: python3 tools/pipeline/postprocess.py in.png --out out.png --palette (접수청 팔레트) --alpha-threshold 128
- 아웃라인과 팔레트 강제. 디더링은 캐릭터에 미사용(ART_STYLE 4장)

## 결과 (2026-08-03 1차 생성)

- 도구: PixelLab Create S-XL image (Pro), 64x64, 16변형 그리드, 배경 제거. Claude in Chrome 조작
- 톤앤매너: 첫 채택 접수 관원 프레임을 스타일 레퍼런스(Pick from gallery)로 걸어 후속 캐릭터를 같은 아웃라인, 셰이딩, 비례, 팔레트로 통일
- 생성 완료:
  - 저승사자: 검은 갓, 검은 두루마기, 창백하고 피곤한 표정, 두루마리. 오프닝 저승사자이자 허브 실수한 차사
  - 접수 관원: 청회색 과로 관원(다크서클, 서류 더미). 허브 접수처 신규 NPC
  - 판관: 붉은 관복 관원. 3막 판관과 저승 관리 계열
  - 감재사자도형 저승사자(화려 무장, 깃털 관모, 소환장): 보류. PixelLab 갤러리 보관
- 저승사자 고증: 감재사자도(국립중앙박물관 소장품번호 구2254, 공공누리 출처표시) 참조 후, 화려 무장형이 저승사자 느낌이 약해 검은 갓과 검은 두루마기형으로 확정
- 미생성(다음 세션): 서기, 주모, 삽살개, 대장장이 도깨비. 같은 스타일 레퍼런스로 이어서 생성
- 파일: art_src/generated/pixellab/frontend/ 인박스(README 참조). 분할과 후처리 후 assets/sprites/npc/ 배치, hub.tscn NPC 플레이스홀더 교체

## 접수 관원 재생성 (2026-08-07, 붉은 도포 확정)

접수 관원의 조형을 청회색에서 붉은 도포로 바꾼다 (docs/DECISIONS.md 2026-08-07, docs/DESIGN_HUB.md 4장). 1차 생성분(청회색)은 폐기하고 새로 만든다. 붉은색을 3막 판관 전용으로 두던 방침은 함께 해제했다.

### 전제 확인 (2026-08-07 실측)

- 로컬 art_src에 붉은 관복 계열 캐릭터는 없다. 캐릭터 zip 40여 건의 프롬프트를 전수 대조해 확인했다
- char_clerk_v1.zip은 이름과 달리 차사다. 프롬프트가 char_saja_v1과 동일하고 파일 크기도 37243바이트로 같다. 재다운로드 중복분이며 archive 대상이다
- 1차 생성 기록의 "판관: 붉은 관복 관원"은 PixelLab 계정에만 있고 저장소로 반입된 적이 없다

### 스타일 레퍼런스

- 파일: art_src/style_refs/char_style_ref_clerk_red.png (256x256, 4x4 그리드, 칸당 64x64)
- 출처: PixelLab creator 영역 미리보기. 사용자가 2026-08-07 제공
- 읽을 것: 붉은 도포와 검은 챙 넓은 관모(패영 포함)의 배색비, 3등신 SD 비례, 굵은 검정 아웃라인, 소품(등롱, 두루마리, 붓)을 든 자세 계열
- 주의: 레퍼런스의 붉은색은 채도가 높다. 접수청은 낡고 물 빠진 저채도로 낮춰 받는다 (DESIGN_HUB 1장 침침한 중채도)

### 생성 설정 (S1, PixelLab)

- 도구: PixelLab 캐릭터 생성. 위 레퍼런스를 Pick from gallery로 걸어 아웃라인과 셰이딩과 비례를 고정한다
- 크기: 64x64 캔버스, 8방향 중 south와 east만 사용 (허브는 가로 진행)
- SUBJECT 프롬프트:

```
2 to 3 head tall SD pixel-art character, thick black outline, side view, clean shading,
overworked korean afterlife reception clerk at a government office window,
faded dull red official robe (dopo), black wide-brim official hat with tassel,
heavy dark circles under tired eyes, carrying a stack of paperwork and a writing brush,
Korean folk afterlife setting, muted twilight office palette, strong readable silhouette
```

- 네거티브 추가분:

```
bright saturated red, glossy new robe, rank badge (hyungbae), sword, armor,
black hooded death robe, grim reaper, japanese shinigami, photorealistic, 3d render
```

- 차사와의 구분: 차사는 검은 갓과 검은 두루마기이고 관원은 붉은 도포와 검은 관모다. 실루엣이 겹치지 않게 관원은 서류 뭉치를 안은 자세를 기본으로 둔다
- 3막 판관과의 구분: 색이 아니라 관모 형태, 흉배 유무, 체구, 배경 격식으로 가른다. 관원은 흉배 없음, 저채도. 판관은 흉배 있음, 고채도 (DECISIONS 2026-08-07)

### 애니메이션 클립 (차사와 동일 골격)

scripts/npc/npc_actor.gd가 그대로 돌아가려면 아래 5종이 필요하다. 차사(char_saja_v3_full)와 같은 구성이다.

| 엔진 클립명 | PixelLab 애니메이션 프롬프트 | 비고 |
|---|---|---|
| idle | Idle | 기본 정지 |
| work | busily flipping through ledger book pages and stamping | 유휴 루프 A |
| work_scroll | unrolling a very long paper scroll and reading down | 유휴 루프 B |
| spaceout | spacing out standing completely still and staring | 가끔 넋 나감 |
| startled | startled jump flinching upward in surprise | 말 걸기 반응, loop 거짓 |

- 방향은 south와 east 두 벌. 나머지 6방향은 받지 않는다
- 클립이 전부 없어도 된다. idle 하나만 있으면 배치는 가능하고 나머지는 이어서 채운다

### 반입과 후처리 (S2)

1. 다운로드 zip을 그대로 pixellab/ 받은편함에 넣는다 (개명하지 않는다)
2. Cowork가 char_clerk_red_v1로 개명해 art_src/generated/pixellab/chars/로 옮긴다
3. 후처리: python3 tools/pipeline/postprocess.py in.png --out out.png --palette (접수청 팔레트) --alpha-threshold 128
4. 차사와 같은 방식으로 방향별 시트를 구워 assets/sprites/npc/clerk_*.png 배치
5. SpriteFrames(assets/sprites/npc/clerk_frames.tres) 생성. 속도는 차사 기준(work 6.0, spaceout 5.0, startled 9.0)
6. scenes/hub/hub.tscn의 NpcClerk 플레이스홀더(ColorRect)를 AnimatedSprite2D + npc_actor.gd로 교체. z는 플레이어보다 낮게, 정적 단일 프레임 금지

- 채택 결과: (반입 후 기록)
