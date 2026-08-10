# 에셋 요청서: 026 이벤트 전용 장면 조형

작성: 2026-08-07
목적: 노름판과 장물아비 추격 이벤트에 쓸 전용 조형을 만든다. 두 이벤트는 지금 다른 곳에서 쓰던 조형을 빌려 쓰고 있어 장면이 어색하다
근거 문서: docs/act1/EVENTS.md 7장 B1(노름판)과 부록 A(장물아비 소굴), docs/act1/ENEMIES.md 5.3(장물아비), docs/ART_STYLE.md 2장과 9장, art_src/requests/019_tone_v2_characters.md(톤 v2 기준), art_src/requests/023_ssireum_event_characters.md(같은 성격의 선행 요청서)
선행: 019 톤 v2 앵커. reference image 1은 art_src/style_refs/char_style_ref_saja_v3.png로 고정한다
사용자 지시 (2026-08-07): 이벤트용 아트를 따로 만든다. 기존 도깨비나 도형을 쓰지 않는다. 씨름판 수준으로 올린다. 노름판은 반대편에 도깨비가 양반다리로 앉아 두 팔을 넓게 벌린 것처럼 보이게 하고 허리 위만 그려도 된다. 추격은 조형을 다 그려 넣고 속도감을 올린다

## A. 배경과 현재 상태

노름판은 잡도깨비 옆모습 스프라이트를 좌우 반전해 세워 두고 멍석으로 하반신을 가려 앉은 것처럼 보이게 했다. 서 있는 몸을 가린 것이라 앉은 자세로 읽히지 않는다.

추격은 플레이어 옆모습 달리기와 잡도깨비 뜀 클립을 탑뷰 골목에 그대로 놓았다. 위에서 내려다보는 화면에 옆모습이 서 있어 방향이 어긋난다. 장애물은 문어굴 보스방의 궤짝과 돌을 빌려 쓴다.

## B. 유닛별 규격

| # | 유닛 | 용도 | 인게임 크기/캔버스 | 비고 |
|---|---|---|---|---|
| 1 | 노름꾼 dokkaebi_gambler | 노름판 건너편에 앉은 상대 | 폭 약 56px 높이 약 40px / 64x48 | 허리 위만. 양반다리로 앉아 두 팔을 넓게 벌린 자세 |
| 2 | 플레이어 뒷모습 달리기 player_back_run | 추격 조작 캐릭터 | 신장 28px / 60x60 | 기존 플레이어의 북쪽 방향. 달리기 4프레임 |
| 3 | 장물아비 뒷모습 도주 fence_back_run | 추격 표적 | 신장 26px / 60x60 | 등에 보따리. 달리기 4프레임 |
| 4 | 탑뷰 장애물 3종 | 추격 골목 바닥 | 24x20 안팎 / 32x32 | 궤짝, 항아리 무더기, 짐수레. 위에서 내려다본 각 |

- 크기 위계: 노름꾼은 상반신만으로도 화면 가로의 8분의 1을 넘긴다. 판을 지배하는 상대로 읽혀야 한다
- 색 채널: 적색 금지(생기 몰림 전용), 청록 금지(도깨비불과 비밀 신호 전용). 난색은 등불 호박까지만 (EVENTS 10.1)

## C. 필요한 컷

### 노름꾼 (3컷)

| 컷 | 단계 | 내용 |
|---|---|---|
| gambler_idle | 제안, 베팅, 패 돌리기 | 양반다리로 앉아 두 팔을 넓게 벌린 기본 자세. 자리를 내주는 손짓 |
| gambler_win | 노름꾼이 이겼을 때 | 두 팔을 더 벌리고 몸을 젖혀 웃는다. 판돈을 끌어가는 자세 |
| gambler_lose | 플레이어가 이겼을 때 | 팔을 안으로 모으고 어깨를 움츠린다. 못마땅한 표정 |

- 셋 다 같은 캔버스, 같은 앉은 높이여야 한다. 자세만 바뀌고 엉덩이 위치는 고정이다
- 허리 아래는 그리지 않는다. 멍석에 가려지는 부분이라 그려도 보이지 않는다

### 추격 (4종)

| 컷 | 내용 |
|---|---|
| player_back_run | 화면 위쪽으로 달려가는 플레이어의 등. 팔을 흔들고 어깨가 좌우로 흔들린다 |
| fence_back_run | 같은 방향으로 달아나는 장물아비의 등. 등에 진 보따리가 흔들린다 |
| chase_crate, chase_jars, chase_cart | 골목 바닥의 장애물. 위에서 내려다본 각 |

- 장물아비 보따리는 담황에서 등불 호박 사이 난색이어야 한다. 우선 포착 신호다 (EVENTS 부록 A.6)
- 장애물 셋은 실루엣이 서로 달라야 한다. 같은 덩어리로 보이면 피할 곳을 못 읽는다

## D. 프롬프트

공통 수식어는 019 B절을 그대로 쓴다.

```
tall lean proportions about 3.5-4 heads, NOT chibi, NOT 2-head SD,
muted low-saturation palette, soft low-contrast shading, dark colored outline,
pale desaturated skin, calm restrained expression,
small pixel art character, flat shading, no baked lighting, no glow
```

### 1. 노름꾼 dokkaebi_gambler

```
korean dokkaebi spirit gambler seen from the front, upper body only cut off at
the waist, sitting cross-legged on the floor, both arms stretched out wide to
the sides with open palms turned up as if offering a seat,
dusky indigo-violet skin, dim warm amber eyes, wild shaggy messy loose hair,
a small dark horn-less topknot-less head, worn dark hanbok jacket open at the
chest with wide sleeves, a pale ochre sash at the waist,
sly amused half-smile, leaning slightly back,
korean not japanese, NO horns, NO oni, NO samurai, NO kimono, NO topknot,
no legs visible, no lower body, no chair, no table
+ 공통 수식어
```

- gambler_win: `both arms flung wider and the torso leaning further back, laughing with the head tilted up`
- gambler_lose: `both arms pulled in close to the chest and the shoulders hunched, scowling with the head lowered`

### 2. 플레이어 뒷모습 달리기 player_back_run

기존 플레이어(char_player_final)의 북쪽 방향을 그대로 쓴다. 새 인물을 만들지 않는다. 달리기 클립만 북쪽 방향으로 생성한다.

```
running forward away from the camera at full stride, seen from directly behind,
both arms swinging, shoulders rocking side to side
```

### 3. 장물아비 뒷모습 도주 fence_back_run

```
korean dokkaebi fence and petty thief running away from the camera,
seen from directly behind, small wiry hunched build,
dusky indigo-violet skin, wild shaggy messy hair,
ragged short dark hanbok jacket and loose knee-length pants, bare feet,
a bulging pale ochre cloth bundle of stolen coins slung on the back,
one hand clutching the bundle strap, glancing back over the shoulder,
korean not japanese, NO horns, NO oni, NO samurai, NO kimono
+ 공통 수식어
```

### 4. 탑뷰 장애물 3종

```
seen from directly above looking straight down, top-down view,
korean joseon era night market alley clutter,
1) a small wooden shipping crate with rope, 2) a cluster of three round dark
clay jars with straw lids, 3) an overturned two-wheeled wooden handcart,
weathered wood and dark clay, muted low-saturation palette, dark colored
outline, flat shading, no baked lighting, no glow, no ground shadow,
no red, no teal
```

### 고정 프롬프트 카드

```
SCALE: subject drawn at exact in-game size on the given canvas, fills most of the canvas
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW (1): flat front view, no perspective, no isometric
VIEW (2,3): directly from behind, top-down runner, no perspective
VIEW (4): directly from above, top-down, no perspective, no isometric
PIXEL: chunky pixel art, low resolution, limited palette, flat shading
```

## E. 판정 기준

- 앵커 정합: 앵커 이미지와 나란히 두고 같은 세계의 인물로 읽히는가
- 노름꾼: 앉은 자세로 읽히는가. 선 몸을 잘라 놓은 것처럼 보이면 기각. 두 팔이 넓게 벌어져 판을 감싸는 실루엣인가
- 노름꾼 3컷: 엉덩이 높이와 캔버스 안 위치가 같은가. 자세만 다른가
- 추격 뒷모습: 위에서 내려다보는 화면에 놓았을 때 달려 나가는 방향이 읽히는가. 옆모습이 섞이면 기각
- 장물아비: 보따리가 난색으로 확실히 눈에 띄는가. 잡도깨비와 구분되는 실루엣인가
- 장애물: 셋의 실루엣이 서로 다른가. 위에서 본 각인가
- 색 채널: 적색과 청록을 쓰지 않는다
- 밀도: 캔버스 = 인게임 크기. 세밀한 대형 밀도 출력은 기각

## F. Godot 연결 계획

- 노름꾼: assets/sprites/enemies/gambler_*.png 3장. scenes/enemies/gambler_frames.tres(idle, win, lose 각 1프레임). gamble_minigame.gd의 DEALER_FRAMES_PATH를 이 경로로 바꾸고, 발밑 기준이 아니라 허리 기준으로 놓도록 배치 상수를 고친다
- 추격 인물: assets/sprites/player/anim/player_back_run_n.png, assets/sprites/enemies/fence_back_run_n.png. chase_minigame.gd가 옆모습 대신 이 시트를 쓴다
- 추격 장애물: assets/sprites/props/chase_*.png 3장. chase_minigame.gd의 OBSTACLE_PATHS를 교체한다
- 조형이 없을 때를 대비해 지금 경로를 폴백으로 남긴다 (ResourceLoader.exists 확인은 이미 있다)

## G. Godot 반영 결과 (완료)

| 파일 | 상수 | 값 |
|---|---|---|
| scenes/minigame/gamble_minigame.gd | GAMBLER_FRAMES_PATH | scenes/enemies/gambler_frames.tres |
| scenes/minigame/chase_minigame.gd | PLAYER_BACK_PATH | scenes/player/player_back_frames.tres |
| scenes/minigame/chase_minigame.gd | THIEF_BACK_PATH | scenes/enemies/fence_back_frames.tres |
| scenes/minigame/chase_minigame.gd | OBSTACLE_PATHS | assets/sprites/props/chase_crate, chase_jars, chase_cart |

굽는 규격

- 노름꾼: 86px 원본을 네 컷 공통 상자로 자른 뒤 0.6배. 50x45. 컷마다 따로 자르면 앉은
  높이와 가로 중심이 흔들려서 공통 상자를 쓴다
- 장물아비: 48px 원본을 네 컷 공통 상자로 자른 뒤 0.6배, 76x76 캔버스에 발밑 57 기준으로
  놓아 가로로 잇는다. 인게임에서 26px이라 플레이어(26px)와 위계가 맞는다
- 장애물: 줄이지 않는다. 화면 깊이 배율(0.52~1.0)이 크기를 잡아 멀면 23px 가까우면 45px다
- 세 벌 모두 알파를 128에서 이진화한다 (bake_wrestler.py와 같은 기준)

배치

- 노름꾼은 좌우를 뒤집지 않고 조형 아래끝을 SEATED_WAIST_Y(152)에 둔다. 멍석 윗변이 148이라
  4px만 걸치고, 벌린 두 팔이 가리지 않는다
- 장물아비는 조형이 보따리를 그려서 갖고 있으므로 코드가 덧그리던 난색 점을 끈다

- 노름판은 GAMBLER_FRAMES_PATH가 DEALER_FRAMES_PATH와 달라지는 순간 _draw_seated_dealer로
  넘어간다. 앉은 조형은 좌우를 뒤집지 않고, 조형 아래끝을 SEATED_WAIST_Y(158)에 맞춰 놓아
  멍석(MAT_TOP_Y 148)이 허리를 덮는다. 배율은 SEATED_SCALE(1.5)
- 추격은 PLAYER_BACK_PATH와 THIEF_BACK_PATH가 폴백과 달라지는 순간 뒷모습 배치로 넘어간다.
  뒷모습 조형은 보따리를 그려서 갖고 있으므로 코드가 덧그리던 난색 점을 끈다
- gambler_frames.tres는 idle 2프레임(기본, 손짓), win 1프레임, lose 1프레임으로 만든다
- fence_back_frames.tres는 run 4프레임으로 만든다

## H. 진행 기록

- 2026-08-07 요청서 작성
- 2026-08-07 생성 완료 (PixelLab Objects). 셋 다 뽑았고 계정에 저장했다
  - 노름꾼 4컷: 86x86, 1방향, 사이드스크롤러, 스타일 레퍼런스 char_style_ref_saja_v3.png.
    양반다리로 앉아 두 팔을 벌린 기본, 손짓, 두 팔 벌려 웃는 승리, 팔짱 끼고 움츠린 패배.
    판정: 앉은 자세로 읽힘, 허리에서 잘림, 뿔과 상투 없음, 적색 없음, 담황 허리띠. 채택
  - 장물아비 뒷모습 6컷: 48x48. 달리기 4컷은 정확한 정면 뒷모습이 아니라 3/4 뒤에서 본
    각이다. 탑뷰 러너에서는 이 각이 오히려 읽히므로 채택. 등의 보따리가 담황으로 뚜렷하다
  - 탑뷰 장애물 7컷: 48x48, 탑뷰. 궤짝, 항아리 무더기, 짐수레, 멍석 묶음, 장작, 통, 소쿠리
- 2026-08-07 내려받기 1차 실패. 개체를 하나씩 Export하면 Chrome 임시 파일 하나만 남고
  최종 이름으로 바뀌지 않아 디스크에 쌓이지 않았다
- 2026-08-08 내려받기 성공과 반영 완료. 갤러리 오른쪽 위 내려받기 아이콘을 눌러 선택 모드로
  들어간 뒤 13개를 체크하고 한 번에 받으면 zip 하나로 떨어진다. 개체별 Export는 쓰지 않는다
  - pixellab/_incoming/event_art_13.zip에서 11개를 이름 붙여 꺼내고 bake_event_art.py로 구움
  - SpriteFrames 3종 생성: gambler_frames.tres(idle 2, win, lose),
    fence_back_frames.tres(idle, run 4), player_back_frames.tres(idle, run 4)
  - 플레이어 뒷모습은 AI로 새로 만들지 않았다. 기존 char_player_final의 북쪽 회전을 그대로
    쓰고 1px 상하 흔들림과 좌우 기울임으로 4프레임을 엮었다
    (DECISIONS 2026-08-07 "플레이어 몸은 AI로 재생성하지 않는다" 준수)
  - 배치 확인: art_src/previz/gamble_previz.png, chase_previz.png
