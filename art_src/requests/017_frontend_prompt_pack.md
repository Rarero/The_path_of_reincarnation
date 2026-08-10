# 에셋 요청서: frontend_prompt_pack (실행용 프롬프트 팩)

작성: 2026-08-03
근거: 요청서 013 014 015 016, docs/ART_STYLE.md 9장, docs/DESIGN_INTRO.md, docs/DESIGN_HUB.md, 세션 A1 A2 진행
용도: 시작화면, 오프닝 컷툰, 허브의 PixelLab 생성 프롬프트를 자산별로 확정한다. 013~016의 프롬프트 절을 대체하는 실행 기준이며, 각 블록은 그대로 복사해 PixelLab에 붙여넣을 수 있다.

## 0. 공통 규칙

- 도구: Create S-XL image (Pro)를 표준으로 한다. Create from style reference(베타)는 실패율 문제로 금지. NPC는 채택 프레임을 스타일 레퍼런스로 건 뒤 Character creator로 방향과 애니메이션을 잇는다.
- 레퍼런스 앵커: 배경과 키비주얼은 act1_mood_anchor.png(렌더와 무드 통일)를 걸되, 허브는 팔레트를 접수청 서브(황혼 관청)로 이동한다. 캐릭터는 채택된 접수 관원/차사 프레임을 Pick from gallery로 걸어 아웃라인, 셰이딩, 비례를 통일한다.
- 캔버스 = 인게임 또는 화면 크기다. PixelLab Pro 상한은 512x512. 타이틀 키비주얼과 컷툰은 상한을 넘는 해상도가 필요하면 별도 도구를 검토한다(ART_PIPELINE 4장).
- 배경 조각은 플랫하고 어둡게 생성한다(무외곽선, 저채도 남색). 밤 침전과 등불 글로우는 에셋에 굽지 않고 엔진 라이팅이 담당한다. 캐릭터와 상호작용 오브젝트만 검정 아웃라인과 높은 대비로 분리한다.
- 예약색: 청록은 도깨비불 신호, 적색은 생기 몰림 신호다. 접수청 배경 장식에는 쓰지 않는다.
- 접수청 팔레트 방향(잠정): faded indigo, ash grey 기조에 dim amber 등불만 포인트. 1막 시장 난색보다 차갑고 침침하게.

### 차사 복장 정정 (중요)

채택본은 검은 갓과 검은 두루마기의 한국 저승사자이고 창백하고 피곤한 관원 인상이다(DESIGN_HUB, frontend README, 세션 A2). 따라서 이 팩은 다음을 013~016 대비 정정한다.

- 프롬프트: 홍철릭, 전립 서술을 빼고 검은 갓(gat)과 검은 두루마기(durumagi)로 서술한다.
- 네거티브: 일반적인 "black robe" 배제어를 삭제한다. 대신 서양 사신 도상만 배제한다(hooded grim reaper, scythe, japanese shinigami).
- 문서 정합(GDD 2장, DESIGN_INTRO 4장)은 사용자 결정 후 별도 반영한다. 이 팩은 채택 아트 기준으로 통일한다.

### 주인공 외형 통일

현대 한국 직장인이다. 걷어올린 흰 드레스 셔츠, 느슨한 넥타이, 슬랙스, 피곤한 눈. 군인 복장이 아니다(GDD 2장). 컷툰 전 컷에서 동일 인물로 유지한다.

### 고정 카드 템플릿

```
SCALE: {크기와 구도}
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: {flat side view / cinematic vista}
PIXEL: chunky pixel art, low resolution, limited palette, flat shading
LIGHT: {unlit flat / cinematic dusk 등 자산별}
CATEGORY(...): {아래 카테고리 중 하나}
SUBJECT: {대상 구체 서술}
```

카테고리:

- CATEGORY(배경): background piece, no outlines, desaturated muted dark indigo and ash grey tones
- CATEGORY(인게임): gameplay object, thin black outline, readable silhouette, higher contrast
- CATEGORY(도깨비): korean dokkaebi, human-shaped, shaggy hair or bamboo hat, hanbok, NO horns, NO oni, NO goblin, no tiger stripes, no spiked club
- CATEGORY(컷툰): cinematic pixel-art comic illustration, painterly, strong readable silhouettes, subtle outline on foreground figures, atmospheric lighting allowed

공통 네거티브 (모든 자산 기본):

```
japanese oni, horns, hooded grim reaper, scythe, japanese shinigami, torii, kanji, hiragana, katakana, chinese red lantern, chinese palace, photorealistic, 3d render, watermark, readable text, neon, cyberpunk, bright daylight, blue sky
```

---

## A. 시작화면

### A1. title_bg (타이틀 키비주얼)

- 도구: Create S-XL image (Pro). 캔버스 16:9 최대 해상도(예 512x288, 미지원 시 512x512 생성 후 크롭). 앵커 act1_mood_anchor(무드), 팔레트 접수청.
- 배치: 좌하단은 메뉴, 좌상단은 로고 오버레이라 비교적 비운다. 시선은 우상단 상행 길과 먼 염라대전으로.

```
SCALE: wide 16:9 title key visual, full-screen composition, lower-left kept simple and calm for menu buttons
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: cinematic side-scroller vista with gentle layered depth, no isometric, no vanishing-point perspective
PIXEL: chunky pixel art, limited palette, painterly pixel-art key visual
LIGHT: solemn twilight, dim amber lantern accents, soft glow allowed (single composited key visual)
CATEGORY(배경): background key visual, desaturated muted dark indigo and ash grey, warm amber only as sparse accents
SUBJECT: the entrance reception office of the Korean afterlife (jeoseung) at dusk; an old Joseon-dynasty government office with tiled low roofs and paper-covered windows; a row of administrative service windows with stacked ledgers and number tickets in the mid-ground; on the far left a dim storage annex with dusty shelves and hanging paper name tags; on the right a long path rising into the far background toward a distant palace silhouette on a hill; a few faint translucent wandering souls queuing; a low waning moon in the twilight sky; quiet, lonely, bureaucratic mood
```

네거티브 추가:

```
modern signage, red dominant palette, cluttered lower-left, character close-up, foreground UI, text logo
```

- 채택 기준: 좌측 3분의 1이 차분한가, 우상단으로 시선이 흐르는가, 저대비 황혼 무드인가, 등불이 점점이 뜨는가.

---

## B. 오프닝 컷툰 (7컷)

- 도구: Create S-XL image (Pro). 캔버스 컷별 512x512 이하(합성은 인게임). 우선 제작: B3 트럭, B4 차사.
- 공통: 각 컷은 개별 생성 후 인게임에서 패널 분할과 캡션을 얹는다. 이름 말풍선은 흐리게 처리해 판독 불가로 둔다(오인 호명 장치). 주인공 외형 고정.
- 공통 SUBJECT 접두: `modern Korean office worker protagonist in his late 20s, rolled-up white dress shirt, loosened tie, slacks, tired eyes;`
- 공통 네거티브 추가: `military uniform, soldier, gun, colorful hanbok on the messenger`

### B1. intro_p1_office (야근 퇴근)

```
SCALE: cinematic comic illustration, 4:3 or square panel
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: cinematic interior then exterior
PIXEL: chunky pixel art, limited palette, painterly
LIGHT: late-night office lit only by a cold monitor glow; a single lonely warm streetlamp outside
CATEGORY(컷툰): cinematic pixel-art comic illustration, painterly, readable silhouettes, atmospheric lighting
SUBJECT: modern Korean office worker protagonist in his late 20s, rolled-up white dress shirt, loosened tie, slacks, tired eyes; alone at a desk in a dark late-night office lit only by his monitor; companion framing of the same man seen from behind walking into an empty night street under one streetlamp; melancholy overtime mood
```

### B2. intro_p2_crosswalk (횡단보도, 호명)

```
SCALE: cinematic comic illustration, square panel
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: cinematic street level
PIXEL: chunky pixel art, limited palette, painterly
LIGHT: night, green pedestrian signal glow, cool street tones
CATEGORY(컷툰): cinematic pixel-art comic illustration, painterly, readable silhouettes
SUBJECT: modern Korean office worker protagonist in his late 20s, rolled-up white dress shirt, loosened tie, slacks; standing at a crosswalk as the pedestrian light turns green; from behind him three faint speech bubbles grow larger and larger calling a name shown as blurred unreadable smudges; ominous quiet
```

### B3. intro_p3_truck (우선)

```
SCALE: cinematic comic illustration, dynamic panel
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: cinematic, tight over-the-shoulder to side
PIXEL: chunky pixel art, limited palette, painterly
LIGHT: night with a harsh white truck headlight blasting from the right, the right frame edge blowing out to pure white
CATEGORY(컷툰): cinematic pixel-art comic illustration, painterly, strong readable silhouettes, high contrast
SUBJECT: modern Korean office worker protagonist in his late 20s, rolled-up white dress shirt, loosened tie; turning his head back over his shoulder in close-up, eyes widening; a truck's headlights blast in from the right side of the frame and the edge blows out into pure white; sense of sudden impact
```

- SFX 표기(인게임): 빵—. 컷 끝은 흰색으로 마감해 코드 화이트 플래시와 연동한다.

### B4. intro_p4_saja (우선)

```
SCALE: cinematic comic illustration, low-angle POV panel
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: low-angle first-person point of view, looking up from the ground
PIXEL: chunky pixel art, limited palette, painterly
LIGHT: dim twilight interior
CATEGORY(컷툰): cinematic pixel-art comic illustration, painterly, readable silhouettes
SUBJECT: low-angle POV of just waking up on the floor, looking up at a Korean afterlife messenger (chasa) leaning over with one hand on his own head; the chasa wears a BLACK Korean wide-brim hat (gat) and a BLACK durumagi robe, pale tired face with dark circles, holding a rolled ledger; an unfamiliar wooden ceiling behind; he looks like a weary government clerk, NOT a hooded grim reaper, NOT a japanese shinigami
```

### B5. intro_p5_mistake (동명이인 오류)

```
SCALE: cinematic comic illustration, two-beat panel
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: cinematic office desk
PIXEL: chunky pixel art, limited palette, painterly
LIGHT: dim office interior
CATEGORY(컷툰): cinematic pixel-art comic illustration, painterly, readable silhouettes
SUBJECT: the black-gat black-durumagi chasa comparing two paper ledgers with cold sweat on his pale face; beside it a small inset of the protagonist's face next to a ledger entry marked with a red mismatch stroke; bureaucratic dread with dry humor; the messenger is a weary clerk, NOT a grim reaper
```

### B6. intro_p6_queue (50년 대기와 특수창고)

```
SCALE: cinematic comic illustration, three-beat panel
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: cinematic hall interior
PIXEL: chunky pixel art, limited palette, painterly
LIGHT: dim amber office light
CATEGORY(컷툰): cinematic pixel-art comic illustration, painterly, readable silhouettes
SUBJECT: an endless queue of faint translucent wandering souls holding paper number tickets at a worn service counter; a dusty hanging wooden plaque for a special storage annex (mark it as an abstract sign, not readable letters); then the protagonist's hardened, determined face in close-up; oppressive endless waiting
```

### B7. intro_p7_resolve (직접 상행 결의)

```
SCALE: cinematic comic illustration, two-beat panel
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: cinematic interior looking toward a rising path
PIXEL: chunky pixel art, limited palette, painterly
LIGHT: twilight with faint amber up the path
CATEGORY(컷툰): cinematic pixel-art comic illustration, painterly, readable silhouettes
SUBJECT: interior of the reception office looking toward a path that rises upward into the far distance with a distant palace silhouette; the protagonist seen from behind, rolling up his sleeves and turning toward the rising path; quiet resolve, upward pull
```

- 캡션(인게임): 염라를 만나러, 위로. 종료 후 허브 진입.

---

## C. 허브 (저승 초입 접수청)

### C-1. 배경 조각 (레이어 조립)

- 도구: Create S-XL image (Pro), 조각별 개별 생성. 앵커 act1_mood_anchor(무드), 팔레트 접수청.
- 공통 규격: 측면 입면 고정, 무외곽선, 저채도 남색과 재빛. 지면선은 조각 하단에 맞춰 인게임 y160에 정합. 광원 방향은 상단(등불). 밤 침전과 글로우는 엔진이 얹으므로 조각은 플랫하고 어둡게.
- 조립: 좌 특수창고, 중앙 창구 열, 우 상행문 순으로 배치. 원경 실루엣 밴드는 상단 뒤에 깐다. 반복 티 방지를 위해 창구와 지면은 변주해 생성한다.

공통 카드(조각 SUBJECT만 교체):

```
SCALE: side-scroller background piece drawn at in-game size on the given canvas, fills the canvas
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: flat side view for a 2D platformer, single ground line, no perspective, no isometric, no depth angle
PIXEL: chunky pixel art, low resolution, limited palette, flat shading
LIGHT: unlit flat, no glow, no halo, no baked lighting
CATEGORY(배경): background piece, no outlines, desaturated muted dark indigo and ash grey tones, dim amber only as tiny lantern dots
SUBJECT: {조각별 서술}
```

조각별 SUBJECT와 캔버스:

- hub_bg_far_palace_band (원경 실루엣, 약 256x96): a distant flat silhouette band of underworld palace roofs on a rise, far background, darkest indigo, barely lit, sits high behind everything
- hub_bg_service_windows (중경 창구, 약 160x110): a row of three Joseon administrative service windows with a low wooden counter, stacked paper ledgers, a number-ticket stand, worn plaster wall; muted indigo and ash grey, tiny amber lantern dot above
- hub_bg_storage_annex (좌 특수창고, 약 120x140): a dim storage annex with wooden shelves, stacked boxes and hanging paper name tags on strings, dusty and quiet, private back-room feel, darkest zone of the office
- hub_bg_upgate (우 상행문, 약 80x140): a tall wooden gateway opening onto a path that rises upward and fades into the distance, a faint amber pull at the top, threshold to leave the hub
- hub_bg_floor (근경 지면, 약 256x28): a worn plank floor strip with faint dust, a stray dropped ledger and a low wooden stool as props, foreground ground band

네거티브 추가(배경):

```
red dominant palette, teal dominant palette, bright daylight, modern signage, people, characters, baked glow
```

- 채택 기준: 조각들이 같은 지면선과 팔레트, 같은 상단 광원을 공유하는가. 인물은 굽지 않았는가(군상은 캐릭터 스케일 별도 스프라이트).

### C-2. NPC 잔여 4종

- 도구: Create S-XL image (Pro) 64x64, 16변형 그리드, 배경 제거. 앵커는 채택된 접수 관원/차사 프레임(Pick from gallery)로 걸어 아웃라인과 셰이딩, 3등신 비례, 팔레트를 통일한다.
- 채택 후: 셀을 골라 Character creator로 승격하고 방향(주로 좌우)과 유휴 애니메이션을 잇는다. 허브 NPC는 정적 금지이므로 유휴 루프를 반드시 만든다(세션 A2의 차사 방식 준용).
- 공통 카드(SUBJECT만 교체):

```
SCALE: 3-head-tall SD character drawn at in-game size on a 64x64 canvas, fills most of the canvas
REFERENCE: match the outline, shading, proportions and palette of reference image 1 (adopted reception-clerk frame)
VIEW: flat side view, west and east facing, no perspective
PIXEL: chunky pixel art, thick black outline, clean flat shading, limited muted twilight-office palette
LIGHT: unlit flat, no baked lighting
SUBJECT: {NPC별 서술}
```

NPC별 SUBJECT:

- npc_seogi (늙은 서기 혼): an old clerk soul, faded Confucian scholar robe and a small scholar's cap, long thin grey beard, holding a scroll ledger and a brush, his lower body fading into a wispy semi-transparent ghost tail; weary but kindly; NOT a grim reaper
- npc_jumo (주모): a middle-aged Korean tavern keeper woman in hanbok jeogori and chima with a work apron, hair in a bun, holding a ladle, plump warm generous build, standing by a small food stall tray
- npc_sapsal (삽살개): a Korean sapsal dog, long shaggy fur hanging over the eyes, friendly folk guardian dog, mascot proportions, four legs, sitting alert
- npc_blacksmith (대장장이 도깨비): a Korean dokkaebi blacksmith, human-shaped folk figure with shaggy hair or a paeraengi bamboo hat, hanbok with sleeves rolled up, sturdy build, holding a smith hammer as a work tool, friendly and mischievous face; NO horns, NO oni, NO tiger-skin clothes, NO spiked iron club, NO solid red or blue skin

네거티브 추가(대장장이 전용):

```
japanese oni, horns, tiger skin, spiked club, red oni mask, solid red skin, solid blue skin, grim reaper
```

- 채택 기준: 채택 프레임과 아웃라인, 비례, 팔레트가 붙는가. 실루엣만으로 역할이 읽히는가. 대장장이는 오니 조형으로 이탈하지 않았는가(reference/act1_dokkaebi 6장 체크리스트 대조).

---

## D. 생성 순서와 채택 루프

1. 허브 배경 조각(C-1). 여기서 접수청 서브 팔레트를 추출해 art_src/palettes/에 고정한다. 이후 자산이 이 팔레트를 따른다.
2. 타이틀 키비주얼(A1). 고정된 팔레트로 생성.
3. 오프닝 컷툰 우선 컷 B3, B4. 이어서 B1 B2 B5 B6 B7. 차사는 채택본(검은 갓, 검은 두루마기)로.
4. 허브 NPC C-2를 서기, 주모, 삽살개, 대장장이 순으로. 채택 프레임 앵커 유지.

- 각 자산 3~5회 반복 후 채택. 채택 결과와 반복 횟수를 요청서 013~016 결과란과 docs/PROGRESS.md에 기록.
- 후처리: 캐릭터는 tools/pipeline/postprocess.py로 팔레트와 알파 강제. 배경 조각은 플랫 유지, 침전은 엔진.

## E. 실행과 문서 반영

- 실행 위치: 이 샌드박스에서는 PixelLab 생성이 불가하다. 아트 세션에서 Claude in Chrome으로 PixelLab 웹을 조작해 위 프롬프트를 돌린다. 현재 A2 세션이 같은 PixelLab을 쓰고 있어 동시 구동 시 충돌하므로 한 번에 한 세션만 생성한다.
- 파일 인계: PixelLab에서 내려받은 ZIP과 PNG를 art_src/generated/pixellab/frontend/에 넣으면 분할과 후처리, 씬 연결을 잇는다(frontend README 절차).
- 문서 정합: 차사 복장(검은 갓, 검은 두루마기)과 3등신 비율 확정을 사용자 결정 후 DECISIONS에 기록하고 GDD 2장, DESIGN_INTRO 4장, 요청서 014 016에 반영한다. 이 팩의 네거티브 정정(black robe 제거)도 함께 반영.
