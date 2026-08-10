# 에셋 요청서: 023 씨름 이벤트 캐릭터

작성: 2026-08-06
목적: 씨름 이벤트(docs/act1/EVENTS.md 5장 N5)에 쓸 씨름꾼 조형과, 플레이어와 씨름꾼이 샅바를 맞잡은 대전 조합 스프라이트를 만든다
근거 문서: docs/act1/ENEMIES.md 5.4(씨름꾼), docs/act1/EVENTS.md 5장 N5(씨름 이벤트), docs/ART_STYLE.md 2장과 9장, art_src/requests/019_tone_v2_characters.md(톤 v2 기준), art_src/requests/018_act1_enemy_mobs.md 4번(씨름꾼 클립 정의)
선행: 019 톤 v2 앵커. reference image 1은 art_src/style_refs/char_style_ref_saja_v3.png로 고정한다
사용자 지시 (2026-08-06): 씨름 도깨비를 넣고, 대전 장면에서 기존 캐릭터를 재활용하지 말고 둘이 씨름하는 캐릭터를 따로 만들어 배치한다

## A. 배경과 현재 상태

씨름 이벤트는 구현이 끝났으나 조형이 전부 임시다. 대전 상대로 잡도깨비 스프라이트를 쓰고, 대결 장면은 플레이어와 잡도깨비를 각각 그린 뒤 그 사이에 샅바 띠를 사각형으로 그려 붙였다. 두 사람이 맞붙은 자세가 아니라 나란히 선 자세라 씨름으로 읽히지 않는다.

018 4번의 씨름꾼은 1차 생성이 기각된 상태다(두 다리, 회갈색, 오거 인상). 이 요청서가 그 재생성을 겸한다.

## B. 조합 스프라이트로 굽는 이유 (조각 단위 생성 원칙의 예외)

두 캐릭터를 따로 만들어 엔진에서 붙이면 맞잡은 손, 겹친 어깨, 서로 버티는 무게중심이 맞지 않는다. 씨름은 두 몸이 하나의 실루엣을 이루는 자세라 분리하면 자세 자체가 사라진다. 서낭당 신목이 오색천을 포함해 구운 것과 같은 판단이다 (DECISIONS 2026-08-05 결정 14).

대신 좌우 밀림은 조합 스프라이트 전체를 옮겨 표현한다. 씨름 게이지를 따라 한 덩어리가 좌우로 움직인다.

## C. 유닛별 규격

| # | 유닛 | 용도 | 인게임 크기/캔버스 | 비고 |
|---|---|---|---|---|
| 1 | 씨름꾼 dokkaebi_wrestler | 전투방 잡몹, 씨름 이벤트 등장과 결과 | 신장 48px/96x96 | 018 4번 재생성 겸함. 잡몹 클립은 018 표를 따른다 |
| 2 | 씨름 대전 조합 ssireum_clinch | 씨름 이벤트 대결 구간 | 폭 약 72px 높이 약 52px/96x64 | 플레이어와 씨름꾼이 한 덩어리 |

- 크기 위계: 씨름꾼이 플레이어(신장 28px)보다 크다. ENEMIES 5.4의 "크고 다부진 장정"과 018의 "크기 위계 씨름꾼 최대"를 지킨다
- 큰 도깨비(황소만 한 장정)는 같은 조형을 2배로 키워 쓴다. 별도 조형이 필요한지는 중간보스 아트 세션에서 판단한다

## D. 필요한 컷

이벤트 단계와 1대1로 대응한다.

| 컷 | 단계 | 내용 | 대상 |
|---|---|---|---|
| wrestler_idle | 판 등장, 선택 | 판 한가운데 선 씨름꾼. 도전하듯 팔짱 또는 손짓 | 씨름꾼 단독 |
| clinch_a | 대결 | 샅바를 맞잡고 팽팽하게 버티는 대치 | 조합 |
| clinch_b | 대결 | 같은 자세에서 몸이 조금 눌린 변형. clinch_a와 2프레임 루프 | 조합 |
| win_player | 결과 (승) | 플레이어가 씨름꾼을 넘겨 눕히고 일어선 순간 | 조합 |
| win_wrestler | 결과 (패) | 씨름꾼이 플레이어를 눕히고 뽐내는 순간 | 조합 |

- 대결 구간 내내 보이는 것은 clinch다. 가장 공들일 컷이다
- 승리 컷 둘은 이긴 쪽이 서 있고 진 쪽이 바닥에 있는 실루엣이어야 한 눈에 읽힌다

## E. 프롬프트

공통 수식어는 019 B절을 그대로 쓴다.

```
tall lean proportions about 3.5-4 heads, NOT chibi, NOT 2-head SD,
muted low-saturation palette, soft low-contrast shading, dark colored outline,
pale desaturated skin, calm restrained expression,
small pixel art character, flat shading, no baked lighting, no glow
```

### 1. 씨름꾼 dokkaebi_wrestler

```
korean dokkaebi spirit wrestler for ssireum korean traditional wrestling,
human-shaped, big sturdy heavy build, broad shoulders, thick legs,
muted dusky indigo-violet skin, dim warm amber eyes, wild shaggy messy loose
mane hair down, knee-length dark hanbok pants and a rolled-up short jacket
open at the chest, a pale ochre satba cloth belt wrapped around the waist and
one thigh, bare open hands, no weapon, standing tall with weight low,
korean not japanese, NO sumo, NO mawashi, NO topknot, NO chonmage, NO samurai,
NO kimono, NO horns, NO oni, no tiger stripes, no spiked club
+ 공통 수식어
```

### 2. 씨름 대전 조합 ssireum_clinch

```
two figures locked together in a korean ssireum wrestling clinch, side view,
left figure is a young korean office worker in a white dress shirt with sleeves
rolled up and dark slacks, right figure is a big korean dokkaebi spirit with
dusky indigo-violet skin and wild shaggy hair in dark hanbok pants,
both bent forward at the waist with heads on each other's shoulder,
each gripping the other's pale ochre satba cloth belt with both hands,
legs braced wide and low, straining against each other, one single silhouette,
korean not japanese, NO sumo, NO mawashi, NO topknot, NO chonmage, NO samurai,
NO kimono, NO horns, NO oni
+ 공통 수식어
```

승리 컷은 위 조합 프롬프트에서 자세 서술만 바꾼다.

- win_player: `the office worker standing upright with one fist raised, the dokkaebi sprawled on the ground beside him`
- win_wrestler: `the dokkaebi standing upright with both arms raised, the office worker sprawled on the ground beside it`

### 고정 프롬프트 카드 (019 E절 형식)

```
SCALE: subject drawn at exact in-game size on the given canvas, fills most of the canvas
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: flat side view for a 2D platformer, no perspective, no isometric, no depth angle
PIXEL: chunky pixel art, low resolution, limited palette, flat shading
```

## F. 판정 기준

- 앵커 정합: 앵커 이미지와 나란히 두고 같은 세계의 인물로 읽히는가
- 씨름 고증: 샅바를 맞잡은 자세인가. 스모(마와시, 상투)로 읽히지 않는가
- 실루엣: 조합 컷이 두 사람이 맞붙은 한 덩어리로 읽히는가. 나란히 선 두 사람으로 보이면 기각
- 크기 위계: 씨름꾼이 플레이어보다 확실히 큰가
- 색 채널: 적색을 쓰지 않는다. 적색은 생기 몰림 전용이다. 샅바는 담황 계열로 간다 (007 검수에서 청적 샅바가 이미 지적됐다)
- 밀도: 캔버스 = 인게임 크기. 세밀한 대형 밀도 출력은 기각

## G. Godot 연결 계획

- 씨름꾼 단독: assets/sprites/enemies/ 아래 배치하고 SpriteFrames를 만든다. resources/minigames/ssireum/의 .tres 3종에서 frames_path에 그 경로를 넣으면 이벤트가 바로 쓴다. 코드 수정은 없다
- 조합: assets/sprites/enemies/ 아래 단일 텍스처로 배치한다. scenes/minigame/ssireum_minigame.gd가 단계별로 조합 컷을 그리도록 고친다. 지금의 캐릭터 두 명 따로 그리기와 샅바 사각형은 제거한다
- 조합을 쓰지 못할 때를 대비해 현행 두 명 따로 그리기 경로는 폴백으로 남긴다

## H. 진행 기록

- 2026-08-06 요청서 작성
- 2026-08-06 씨름꾼 생성 완료, 채택. PixelLab Characters v3, 사이드스크롤러, 48x48, Low detail, 단색 아웃라인. 산출은 92x92 캔버스에 8방향 Idle이고 옆모습 실측 19x44다. id c12e7bfb-34f6-4f87-87be-1f76bcc171ed
  - 판정: 샅바 착용, 스모 아님, 뿔과 상투 없음, 적색 없음, 담황 샅바, 남보라 계열 피부에 난색 눈. 018 1차 기각 사유(두 다리 회갈색 오거 인상)를 벗어났다. 채택
  - 남은 아쉬움: 피부가 남보라보다 자보라에 가깝다. 잡도깨비와 나란히 두었을 때 계열이 어긋나면 색만 후보정한다
  - 클립은 Idle 하나뿐이다. 018 표의 hop_move, stance, grab, throw, stun, hurt는 미생성이며 전투방 구현(G2 계열) 전에 채운다
  - 원본 보관: art_src/generated/pixellab/chars/act1_wrestler_v2.zip과 act1_wrestler_v2_idle/. 중복 다운로드 2건은 _to_delete/로
- 2026-08-06 인게임 반영 완료
  - tools/pipeline/bake_wrestler.py 신설. 옆모습을 기존 캐릭터 규격(76x76 캔버스, 가로 중심 40, 발밑 57)에 다시 놓는다. 그 규격이 ssireum_minigame.gd의 ART_CENTER와 같아 코드를 건드리지 않는다
  - assets/sprites/enemies/wrestler_idle_e.png (76x76, bbox 30,13,49,57)
  - scenes/enemies/wrestler_frames.tres (idle 1프레임)
  - resources/minigames/ssireum/의 .tres 3종에 frames_path 연결, placeholder_art false
- 2026-08-06 조합 스프라이트 착수. PixelLab Objects로 16셀 그리드를 뽑는 방식을 잡았다. 1방향, 사이드스크롤러, 스타일 레퍼런스로 art_src/style_refs/char_style_ref_ssireum_pair.png(플레이어와 씨름꾼을 나란히 둔 3배 확대본) 업로드. 크기 96px 설정과 생성은 브라우저 확장 연결이 끊겨 중단
