# 에셋 요청서: 019 톤앤매너 v2 캐릭터 재생성 1차 (저승사자, 플레이어, 잡도깨비, 도깨비불)

작성: 2026-08-04
목적: 캐릭터 톤앤매너 전면 개정(DECISIONS 2026-08-04)에 따라 전 캐릭터를 새 화풍으로 재생성한다. 이 요청서는 사용자가 지정한 1차 4종의 규격과 프롬프트를 정의한다
근거 문서: docs/ART_STYLE.md 2장(새 캐릭터 규격), 3장(캐릭터 채도 규칙), 9장(프롬프트 카드와 앵커 운영), docs/DESIGN_HUB.md 4장(저승사자 NPC), docs/act1/ENEMIES.md 5.1(잡도깨비), docs/DESIGN_ACT1.md 3.5(도깨비불 발판)

## A. 제작 순서 (2026-08-04 사용자 지정)

1. 저승사자 (허브 NPC 실수한 차사 = 오프닝 저승사자)
2. 플레이어
3. 잡도깨비
4. 도깨비불

순서의 의미: 저승사자는 앵커 원본과 같은 소재라 화풍 재현 검증에 가장 유리하다. 인게임 규격의 첫 채택본(순서상 저승사자)이 캐릭터 앵커를 교체한다 (ART_STYLE 9장). 잡도깨비 채택본은 요청서 018 잡몹 5종의 새 스타일 앵커가 된다.

## B. 공통 규칙 (전 유닛)

- 앵커: 모든 생성에 art_src/style_refs/char_anchor_jeoseungsaja.png를 reference image 1로 첨부한다. 팔레트, 렌더링, 무드를 이 이미지에 맞춘다
- 비례: 3.5~4등신 (잡도깨비는 3등신 내외 허용). chibi, 2등신 SD 금지. 프롬프트에 부정 지시 명시
- 렌더링: 저채도 무채 기조, 저대비 4~5단 램프, 창백한 피부, 어두운 유채 흑색 외곽선, 내부 선 절제, 절제된 표정. 밝은 포인트는 소품 1~2개
- 크기: 캔버스 크기 = 인게임 등장 크기. 앵커의 90px 밀도로 이탈한 출력(세밀한 대형 일러스트풍)은 기각한다
- 라이팅: 플랫(알베도) 생성. 발광, 글로우, 강한 명암 금지. 조명은 엔진 담당
- 도구: Character creator v3(sidescroller camera) 표준. East 사용, West 미러
- 프롬프트 공통 수식어 (모든 유닛의 서술에 포함):

```
tall lean proportions about 3.5-4 heads, NOT chibi, NOT 2-head SD,
muted low-saturation palette, soft low-contrast shading, dark colored outline,
pale desaturated skin, calm restrained expression,
small pixel art character, flat shading, no baked lighting, no glow
```

## C. 유닛별 규격

| # | 유닛 | 용도 | 인게임 크기/캔버스 | 비고 |
|---|---|---|---|---|
| 1 | 저승사자 | 허브 NPC, 오프닝 | 신장 약 32px(갓 포함)/64x64 | 채택 시 캐릭터 앵커로 승격 |
| 2 | 플레이어 | 조작 캐릭터 | 신장 28px/64x64 | 16px = 1m 기준 1.75m. 총검 동작 여유 캔버스 |
| 3 | 잡도깨비 | 1막 잡몹 | 신장 40px/76x76 | 018 규격 유지. 채택 시 잡몹 앵커로 승격 |
| 4 | 도깨비불 | 발판/비밀 신호 (게임플레이 요소) | 코어 10~12px/24x24 | 점등/소등 2상태. 청록은 예약 신호색의 허용 예외 |

크기는 초안이며 인게임 확인 후 확정한다 (Windows 검증 항목 G).

## D. 유닛별 프롬프트와 클립

### 1. 저승사자 jeoseungsaja (실수한 차사)

앵커 원본과 동일 소재. 목표는 앵커의 인상(검은 갓, 검은 두루마기, 창백하고 피곤한 얼굴, 두루마리)을 인게임 규격에서 재현하는 것이다.

프롬프트:

```
korean jeoseung-saja, the underworld reaper official, wearing a wide-brimmed
black gat (korean traditional horsehair hat) and a long black durumagi robe,
pale gray tired face, half-lidded weary eyes, faint frown, holding a rolled
white paper scroll in one hand, overworked bureaucrat mood
+ 공통 수식어 (B)
korean not japanese, NO kimono, NO samurai, NO chonmage
```

클립 (허브 NPC 유휴 루프, DESIGN_HUB 4장과 NPC 애니메이션 필수 지침):

| 클립 | 프레임 | 동작 서술 |
|---|---|---|
| idle | 6~8 | standing, slow tired breathing, scroll in hand |
| work_ledger | 8 | busily flipping and stamping ledger pages |
| work_scroll | 8 | reading a very long scroll list, jotting notes |
| spaceout | 6 | staring blankly into the distance, motionless |
| startled | 6 | startled jump with a small squash-and-stretch pop |

### 2. 플레이어 player

설정 준수: 야근 후 밤길에 끌려온 청년. 소매 걷은 흰 셔츠, 느슨한 넥타이, 슬랙스, 소총은 어깨끈으로 어설프게 멘다 (DECISIONS 2026-08-03). 셔츠의 흰색이 이 캐릭터의 밝은 포인트다.

프롬프트:

```
young korean office worker pulled into the underworld, white dress shirt with
sleeves rolled up, loose dark necktie, dark slacks, a rifle slung awkwardly
across the back on a strap, tired but determined pale face, slightly disheveled
short hair
+ 공통 수식어 (B)
```

클립 (M1 컨트롤러 기준. 몸 동작은 무기 비귀속으로 설계한다):

| 우선 | 클립 | 프레임 | 동작 서술 |
|---|---|---|---|
| 1 | idle | 6~8 | standing alert, slight breathing |
| 1 | run | 8 | running forward |
| 1 | jump | 4~6 | rising jump pose |
| 1 | fall | 4~6 | falling pose |
| 1 | shoot | 6 | shouldering the rifle and firing forward |
| 1 | bayonet | 6~8 | a quick close-range bayonet thrust |
| 2 | dash | 4~6 | a short burst dash, body low |
| 2 | reload | 8 | working the rifle to reload |
| 2 | hurt | 4~6 | recoiling from a hit |
| 2 | wall_slide | 4 | sliding down a wall, braced |

- 우선 1을 먼저 생성해 인게임 교체와 앵커 검증을 진행하고, 우선 2를 후속 배치로 채운다

### 3. 잡도깨비 dokkaebi_grunt

018의 모션 정의를 유지하고 화풍만 새 톤으로 바꾼다. 남보라 피부와 도깨비 고증은 유지하되 채도를 새 톤 기준으로 누른다.

프롬프트:

```
korean dokkaebi grunt spirit, human-shaped, wild shaggy hair, muted dusky
indigo-violet skin, dim warm amber eyes, tattered dark hanbok, holding a plain
wooden club as a tool, slightly hunched stance
+ 공통 수식어 (B) (비례는 about 3 heads tall로 조정)
korean dokkaebi, NO horns, NO oni, NO goblin, no tiger stripes, no spiked club
korean not japanese, NO sumo, NO mawashi, NO topknot, NO chonmage, NO samurai, NO kimono
```

클립 (018 D-1과 동일):

| 클립 | 프레임 | 동작 서술 | 예고 |
|---|---|---|---|
| idle | 6 | standing, restless shifting | - |
| hop | 6~8 | hopping forward | - |
| attack | 6~8 | a heavy club swing forward | 팔 부위 하이라이트 + 예고음 |
| charge | 8~9 | crouching low then a short quick ground dash | 웅크림 예비 크게. 다리 하이라이트 + 예고음 |
| hurt | 6 | recoiling from a hit | - |

### 4. 도깨비불 dokkaebi_fire

게임플레이 요소 (발판, 비밀 신호). 청록 예약색의 허용 예외 3건 중 하나다 (DESIGN_ACT1 2.4). 발광은 엔진이 담당하므로 스프라이트는 플랫한 청록 코어만 그린다.

프롬프트:

```
small korean dokkaebi-bul wisp, a floating teardrop flame of cold teal fire
with a short trailing tail, flat solid teal color blocks with darker teal core,
tiny simple pixel art object, dark colored outline, flat shading,
no glow, no halo, no baked light
```

클립:

| 클립 | 프레임 | 동작 서술 |
|---|---|---|
| idle_lit | 4~6 | flame flickering and bobbing gently (loop) |
| idle_unlit | 4 | a dim faint ember, barely wavering (loop) |
| ignite | 4 | the ember flaring up into the lit flame (전환) |

- 점등/소등 상태는 등불 도깨비 처치 연동 규칙(DESIGN_ACT1 3.5)에 사용한다
- 발판 판정 크기와 코어 크기의 정합은 Windows에서 확인 후 확정

## D-2. 생성 실행 카드 (ART_STYLE 9장 고정 카드 조립본)

D의 서술을 9장 고정 프롬프트 카드 형식으로 조립한 최종 입력값이다. PixelLab에 이 텍스트를 그대로 넣는다. reference image 1은 art_src/style_refs/char_style_ref_saja_v3.png(v3 East idle 실측 53x86, 26색)로 고정한다.

### 0. 저승사자 인게임판 saja_ingame (32px / 64x64)

2026-08-05 결정에 따른 소형 재생성분. 이 채택본이 ART_STYLE 9장 캐릭터 앵커가 된다.

```
SCALE: subject drawn at exact in-game size on a 64x64 canvas, fills most of the canvas
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: flat side view for a 2D platformer, no perspective, no isometric, no depth angle
PIXEL: chunky pixel art, low resolution, limited palette, flat shading
LIGHT: unlit, no glow, no halo, no baked lighting
CATEGORY: character sprite, tall proportions about 3.5-4 heads, NOT chibi, NOT 2-head SD,
muted low-saturation palette, soft low-contrast shading, dark colored outline,
calm restrained expression, pale desaturated skin
SUBJECT: korean jeoseung-saja the underworld reaper official, wide-brimmed black gat
korean traditional horsehair hat, long black durumagi robe, pale gray tired face,
half-lidded weary eyes, faint frown, holding a rolled white paper scroll in one hand,
overworked bureaucrat mood, korean not japanese, NO kimono, NO samurai, NO chonmage
```

### 1. 플레이어 player (28px / 64x64)

```
SCALE: subject drawn at exact in-game size on a 64x64 canvas, fills most of the canvas
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: flat side view for a 2D platformer, no perspective, no isometric, no depth angle
PIXEL: chunky pixel art, low resolution, limited palette, flat shading
LIGHT: unlit, no glow, no halo, no baked lighting
CATEGORY: character sprite, tall proportions about 3.5-4 heads, NOT chibi, NOT 2-head SD,
muted low-saturation palette, soft low-contrast shading, dark colored outline,
calm restrained expression, pale desaturated skin
SUBJECT: young korean office worker pulled into the underworld, white dress shirt with
sleeves rolled up, loose dark necktie, dark slacks, a rifle slung awkwardly across the
back on a strap, tired but determined pale face, slightly disheveled short hair,
the white shirt is the only bright accent, korean not japanese
```

### 2. 잡도깨비 dokkaebi_grunt (40px / 76x76)

채택 시 요청서 018 잡몹 앵커가 된다.

```
SCALE: subject drawn at exact in-game size on a 76x76 canvas, fills most of the canvas
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: flat side view for a 2D platformer, no perspective, no isometric, no depth angle
PIXEL: chunky pixel art, low resolution, limited palette, flat shading
LIGHT: unlit, no glow, no halo, no baked lighting
CATEGORY: character sprite, proportions about 3 heads, NOT chibi, NOT 2-head SD,
muted low-saturation palette, soft low-contrast shading, dark colored outline,
calm restrained expression
CATEGORY(도깨비): korean dokkaebi, human-shaped, shaggy hair, hanbok,
NO horns, NO oni, NO goblin, no tiger stripes, no spiked club
korean not japanese, NO sumo, NO mawashi, NO topknot, NO chonmage, NO samurai, NO kimono
SUBJECT: korean dokkaebi grunt spirit, human-shaped, wild shaggy hair, muted dusky
indigo-violet skin, dim warm amber eyes, tattered dark hanbok, holding a plain wooden
club as a tool, slightly hunched stance
```

### 3. 도깨비불 dokkaebi_fire (코어 10~12px / 24x24, 점등과 소등 2상태)

게임플레이 요소라 캐릭터 블록이 아니라 인게임 오브젝트 블록을 쓴다. 청록은 예약 신호색의 허용 예외다 (DESIGN_ACT1 2.4).

점등:

```
SCALE: subject drawn at exact in-game size on a 24x24 canvas, fills most of the canvas
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: flat side view for a 2D platformer, no perspective, no isometric, no depth angle
PIXEL: chunky pixel art, low resolution, limited palette, flat shading
LIGHT: unlit, no glow, no halo, no baked lighting
CATEGORY: gameplay object, thin dark outline, readable silhouette, higher contrast
SUBJECT: small korean dokkaebi-bul wisp, a floating teardrop flame of cold teal fire with
a short trailing tail, flat solid teal color blocks with a darker teal core, tiny simple
shape, no glow, no halo, no baked light
```

소등:

```
(위와 동일한 헤더)
SUBJECT: a dim faint dying ember of the same teal wisp, mostly dark with only a small
faint teal core, barely visible, same shape and same size as the lit version,
no glow, no halo, no baked light
```

- 소등은 점등본을 reference image 2로 추가해 형태 동일성을 강제한다

## E. 판정 기준

- 앵커 정합: 앵커 이미지와 나란히 두고 같은 세계의 인물로 읽히는가 (팔레트, 램프 대비, 선 처리)
- 비례: 3.5~4등신(잡도깨비 3등신 내외). chibi 인상이면 기각
- 밀도: 캔버스 = 인게임 크기. 세밀한 대형 밀도 출력은 기각
- 채도: 의상 대면적이 저채도인가. 밝은 포인트가 소품 1~2개로 제한되는가
- 실루엣: 4종과 기존 유닛이 실루엣만으로 구분되는가. 저대비 화풍에서 배경 대비 명도 분리가 확보되는가
- 고증: 잡도깨비는 뿔/오니/고블린 없음, 일본 요소 없음

## F. 채택 후 처리

- 저승사자 채택 시: ART_STYLE 9장 캐릭터 앵커를 채택본으로 교체하고 char_anchor_jeoseungsaja.png는 화풍 원본으로 보관
- 잡도깨비 채택 시: 요청서 018의 잡몹 앵커(char_dokkaebi_v4)를 대체. 018 잔여 4종(등불, 장물아비, 씨름꾼, 달걀)은 새 앵커로 재생성
- 에셋화와 Godot 연결은 018 E의 표준을 따른다 (스트립 시트, SpriteFrames, 발 기준선)

## G. Windows 인게임 검증 항목

- 4종을 인게임 스케일로 배치해 크기 초안(C) 확정. 특히 플레이어 28px에서 3.5~4등신의 실루엣과 모션 가독성
- 저대비 화풍이 배경 위에서 읽히는지 (명도 분리, 엔진 라이팅 보완 여부)
- 도깨비불 점등/소등 상태 구분과 발판 판정 정합
- 허브에서 저승사자 유휴 루프 전환(work_ledger, work_scroll, spaceout, startled) 자연스러움

## 생성 진행 기록

- 2026-08-04 저승사자 베이스 생성 완료 (id 5a9a7868). Character creator v3의 Create from Reference에 구 저승사자 원본을 활용 (사용자 지시 "원본 최대한 활용"). 원본 4배 확대본을 픽셀 원단위로 정리한 char_anchor_jeoseungsaja_1x.png(66x98, 16색 양자화)를 입력. 캔버스 176x176, 캐릭터 실측 약 66x91, 8방향, 사이드뷰. 원본 인상(갓, 두루마기, 창백한 얼굴, 두루마리) 유지 양호. Export 다운로드 완료(Downloads)
- 2026-08-04 유휴 애니메이션 5클립 등록 (East, 8프레임): idle(v3 템플릿), work_ledger, work_scroll, spaceout, startled(Custom Animation V3). 백그라운드 생성
- 2026-08-05 애니메이션 6클립 완료(idle 템플릿 재등록 1회). 전체 Export를 chars/char_saja_v3_full.zip으로 보관. East 스트립 5종과 saja_v3_frames.tres로 에셋화, hub.tscn 적용(scale 0.45 임시). 상세는 PROGRESS 2026-08-05
- 2026-08-05 인게임 32px판 방식 결정: (b) 소형 재생성 채택, (a) S2 다운스케일 기각 (DECISIONS 2026-08-05). 다운스케일 검증본 art_src/work/tone_v2/saja_downscale_compare.png에서 86px -> 32px(0.372배) 세 방식 모두 표정 소실, 외곽선 붕괴 또는 중간 계조 과다를 확인. 이 결과물이 캐릭터 앵커가 되므로 밀도 품질을 비용보다 우선한다
- v3 90px 베이스는 화풍 원본으로 보관하고(구 char_anchor_jeoseungsaja.png 대체), 소형 재생성의 reference image 1로 쓴다. 인게임 앵커(32px)와 화풍 원본(90px)을 분리 운영한다
- hub.tscn NpcChasa/Anim의 임시 scale 0.45는 32px 채택본 적용 시 1.0으로 복구하고 offset을 64x64 캔버스 기준으로 재실측한다
