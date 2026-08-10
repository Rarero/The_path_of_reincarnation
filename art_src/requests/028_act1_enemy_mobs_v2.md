# 에셋 요청서: 028 1막 잡몹 v2 (장물아비, 달걀도깨비, 짐꾼 도깨비, 씨름꾼 클립 보충)

작성: 2026-08-09
목적: 2026-08-09에 코드로 구현된 1막 신규 4종의 캐릭터 스프라이트와 모션을 톤앤매너 v2 기준으로 생성한다. 현재 넷 다 잡도깨비 프레임을 색과 크기만 바꿔 쓰는 자리표시 상태이며, 화면에서 서로 구분되지 않는다
근거 문서: docs/act1/ENEMIES.md 5.3~5.6(개체별 판별 신호와 모션), docs/ART_STYLE.md 2장(새 캐릭터 규격) 3장(채도) 9장(프롬프트 카드와 앵커), 요청서 019(톤앤매너 v2 기준), 요청서 018(모션 세트 표준 A와 예고 신호 표준 B는 그대로 유효)
선행 기준: 앵커는 art_src/style_refs/char_style_ref_saja_v3.png. 019 채택본 잡도깨비가 잡몹 스타일 앵커다. 남보라 피부, 저채도 무채 기조, 검정에 가까운 유채 외곽선, 플랫 알베도

## A. 지금 상태

| 유닛 | 코드 | 아트 | 자리표시 |
|---|---|---|---|
| 장물아비 | 구현 완료 (enemy_fence) | 군상 그리드 셀 2,1 전용 (thief_idle_e.png) | idle 1프레임. 나머지 클립이 idle 재사용 |
| 씨름꾼 | 구현 완료 (enemy_wrestler) | act1_wrestler_v2 (wrestler_idle_e.png) | idle 1프레임. 나머지 클립이 idle 재사용 |
| 달걀도깨비 | 구현 완료 (enemy_egg) | PixelLab 신규 생성 (egg_idle_e.png) | idle 1프레임. 나머지 클립이 idle 재사용 |
| 짐꾼 도깨비 | 구현 완료 (enemy_porter) | 군상 그리드 셀 7,2 전용 (porter_idle_e.png) | idle 1프레임. 나머지 클립이 idle 재사용 |

2026-08-09 군상 재활용: 배경 군상 그리드(art_src/generated/pixellab/grids/act1_crowd_grid.png, 64셀)에서 장물아비와 짐꾼에 그대로 쓸 수 있는 인물을 찾아 잘라 썼다. 셀 2,1은 허리에 장물 바구니를 메고 한 손에 물건을 든 도깨비이고, 셀 7,2는 패랭이를 쓰고 큰 짐 덩어리를 진 인물이다. 굽는 스크립트는 tools/pipeline/bake_enemy_placeholders.py다. 배경 밀도(25~29px)로 생성된 원본이라 NEAREST 1.5배로 올려 적 규격(40px 안팎)에 맞췄다.

달걀도깨비는 그리드에 대응 인물이 없어 2026-08-09에 PixelLab 웹 UI로 새로 생성했다. Objects 도구, Sidescroller, 48px, 1 Direction, 아래 D-1 프롬프트. 16프레임 중 남보라 바탕에 난색 얼룩이 고르게 퍼진 1번을 채택했다. 원본 `art_src/generated/pixellab/chars/act1_egg_v1.png`(48x48), 인게임분 `assets/sprites/enemies/egg_idle_e.png`(21x26, 알파 트림 후 NEAREST 축소).

개체 식별은 `scenes/levels/stage_enemy_check.tscn`으로 한다. 6종이 정해진 순서로 서고 화면 위에 순서가 적힌다. 인게임에 이름표는 띄우지 않는다 (2026-08-09 사용자 지시).

## B. 공통 생성 설정 (019 B와 동일)

- 도구: Character creator v3 (sidescroller camera). East 사용, West는 미러
- 라이팅: 플랫 알베도. 발광, 글로우, 강한 명암 금지. 조명은 엔진 담당
- 캔버스 크기 = 인게임 등장 크기. 대형 일러스트풍 출력은 기각
- reference image 1: art_src/style_refs/char_style_ref_saja_v3.png 고정
- 고증 강제: 뿔, 오니, 고블린, 호피 무늬, 가시 철퇴 금지. 일본 요소 전면 배제

## C. 규격

| # | 유닛 | 씬 파일명 | 신장/캔버스 | 우선순위 |
|---|---|---|---|---|
| 1 | 짐꾼 도깨비 | dokkaebi_porter | 44px / 88x88 | 1 (군상 임시분 사용 중, 전용 클립 필요) |
| 2 | 장물아비 | dokkaebi_thief | 40px / 76x76 | 2 (군상 임시분 사용 중) |
| 3 | 씨름꾼 | dokkaebi_wrestler | 48px / 96x96 | 3 (idle 있음, 나머지 클립만) |
| 4 | 달걀도깨비 | dokkaebi_egg | 26px / 52x52 | 완료 (idle). 구르기 클립만 남음 |

## D. 프롬프트 카드 (PixelLab에 그대로 붙여 넣는다)

### 1. 달걀도깨비 dokkaebi_egg (26px / 52x52)

```
SCALE: subject drawn at exact in-game size on a 52x52 canvas, fills most of the canvas
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: flat side view for a 2D platformer, no perspective, no isometric, no depth angle
PIXEL: chunky pixel art, low resolution, limited palette, flat shading
LIGHT: unlit, no glow, no halo, no baked lighting
CATEGORY: creature sprite, muted low-saturation palette, soft low-contrast shading,
dark colored outline, NOT chibi humanoid, no face features
SUBJECT: korean dalgyal-dokkaebi the egg goblin, a perfectly smooth featureless
egg-shaped body standing upright, dusky indigo-violet purple color, NOT pale, NOT pink,
faint warm ochre mottled patches on the shell, no eyes no nose no mouth, no ears,
no arms, no legs, no bumps, no cracks, completely smooth surface,
korean folklore spirit, NO horns, NO oni, NO goblin face
```

클립 (018 A 기준)

| 클립 | 프레임 | 동작 서술 (Custom V3) | 예고 |
|---|---|---|---|
| idle | 4 | standing still, barely breathing tilt | - |
| vibrate | 6 | trembling in place, shaking side to side before rolling | 구르기 예고. 진동 폭을 크게 |
| roll | 8 | rolling forward fast, full rotation | - |
| bounce | 6 | bouncing back after hitting a wall, wobbling | 튕김 경직 |
| hurt | 4 | recoiling from a hit | - |

### 2. 짐꾼 도깨비 dokkaebi_porter (44px / 88x88)

```
SCALE: subject drawn at exact in-game size on an 88x88 canvas, fills most of the canvas
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: flat side view for a 2D platformer, no perspective, no isometric, no depth angle
PIXEL: chunky pixel art, low resolution, limited palette, flat shading
LIGHT: unlit, no glow, no halo, no baked lighting
CATEGORY: character sprite, stocky heavy proportions about 3 heads tall,
NOT chibi, NOT 2-head SD, muted low-saturation palette, soft low-contrast shading,
dark colored outline, pale desaturated skin, calm restrained expression
SUBJECT: korean dokkaebi market porter, thickset burly build, muted dusky
indigo-violet skin, wild shaggy hair, plain dark hanbok work clothes with rolled
sleeves, carrying a huge bundled load on a wooden A-frame carrier jige strapped
to the back, the load is a big earthenware jar and stacked firewood and cloth
bundles held with straw rope, the load is turned to the front side as a shield,
leaning forward under the weight, korean not japanese,
NO horns, NO oni, NO goblin, no tiger stripes, no spiked club, NO kimono, NO samurai
```

클립

| 클립 | 프레임 | 동작 서술 | 예고 |
|---|---|---|---|
| idle | 6 | standing braced behind the load, shifting weight | - |
| hop | 8 | slowly pushing forward, shoving the load ahead | 밀어붙이기 |
| turn | 6 | slowly turning around, the load swinging wide | 회전 지연이 이 클립 길이다 |
| attack | 8 | swinging the whole load forward in a wide arc | 짐 부위 하이라이트 + 예고음 |
| hurt | 4 | staggering back | - |
| guard_break | 6 | the load bursting apart, cargo scattering | 짐 파괴 |

부위 요구: 짐(load)이 몸과 시각적으로 분리돼 보여야 한다. 정면 가드가 짐 각도로 결정되고 짐만 따로 부서지므로, 몸과 짐의 실루엣 경계가 뚜렷해야 한다.

### 3. 장물아비 dokkaebi_thief (40px / 76x76)

```
SCALE: subject drawn at exact in-game size on a 76x76 canvas, fills most of the canvas
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: flat side view for a 2D platformer, no perspective, no isometric, no depth angle
PIXEL: chunky pixel art, low resolution, limited palette, flat shading
LIGHT: unlit, no glow, no halo, no baked lighting
CATEGORY: character sprite, lean wiry proportions about 3 heads tall,
NOT chibi, NOT 2-head SD, muted low-saturation palette, soft low-contrast shading,
dark colored outline, pale desaturated skin, sly narrow-eyed expression
SUBJECT: korean dokkaebi fence and pickpocket, skinny quick build, muted dusky
indigo-violet skin, wild shaggy hair, dark ragged hanbok tucked for running,
carrying a fat cloth bundle bojagi knotted on the back full of stolen goods,
one hand reaching out with grabbing fingers, crouched sneaking posture,
korean not japanese, NO horns, NO oni, NO goblin, NO kimono, NO samurai
```

클립

| 클립 | 프레임 | 동작 서술 | 예고 |
|---|---|---|---|
| idle | 6 | crouched, glancing around | - |
| run | 8 | fast light running | - |
| snatch | 8 | reaching out and snatching with one hand | 손 부위 하이라이트 + 예고음 |
| flee | 8 | running away clutching the swollen bundle | 보따리가 부푼 상태 |
| dig | 8 | crouching and digging into the ground with both hands | 이탈 예고. 크고 느리게 |
| hurt | 4 | recoiling from a hit | - |

부위 요구: 보따리가 강탈 전과 후로 크기가 달라야 한다. 강탈 보유 상태를 실루엣으로 읽게 한다 (5.3 판별 신호).

### 4. 씨름꾼 dokkaebi_wrestler (48px / 96x96, 클립 보충)

베이스는 이미 채택됐다 (act1_wrestler_v2, wrestler_idle_e.png). idle 외 클립이 없어 현재 전부 idle을 재사용한다. 아래 클립만 추가 생성한다. 베이스 재생성이 필요하면 018 C의 교정 지침(씨름 고증, 샅바, 일본 요소 배제, 두 다리 허용)을 그대로 쓴다.

| 클립 | 프레임 | 동작 서술 | 예고 |
|---|---|---|---|
| stance | 6 | dropping into a low ssireum wrestling stance, arms open | 선행 예고. 가장 크고 읽기 쉬운 실루엣 |
| hop_move | 8 | hopping forward on one leg | - |
| charge | 9 | crouching then leaping forward in a long dash | 다리 하이라이트 + 예고음 |
| grab | 8 | lunging and seizing with both arms | 손 하이라이트 + 예고음. 슈퍼아머 구간 |
| throw | 8 | hip-throwing the grabbed target over the shoulder | - |
| stun | 6 | dazed after crashing into a wall, wobbling | 반격 창 |
| hurt | 4 | recoiling from a hit | - |

## D-0. 생성 경로

웹 UI가 기본이다. PixelLab에 로그인해 Objects(단일 개체) 또는 Characters(8방향과 애니메이션)를 열고 아래 D의 카드를 그대로 붙여 넣는다. 2026-08-09 달걀도깨비가 이 경로로 생성됐다. Objects 설정은 Directions 1, Size 48px, View Sidescroller였고 16프레임 그리드에서 하나를 골랐다.

### API로 생성하기 (선택)

웹 UI를 쓰지 않고 이 요청서의 프롬프트로 바로 생성하려면 `tools/pipeline/gen_pixellab.py`를 쓴다. 저장소 루트에 `.env`를 만들고 `PIXELLAB_SECRET`을 넣어야 한다 (docs/ART_PIPELINE_SETUP.md 5장). `.env`는 .gitignore 대상이다.

```
python tools/pipeline/gen_pixellab.py --list
python tools/pipeline/gen_pixellab.py egg
```

엔드포인트는 `POST https://api.pixellab.ai/v2/create-image-pixflux`이고 응답의 `image.base64`를 그대로 png로 저장한다. 종량 과금이라 프롬프트를 확정한 뒤 부른다. 결과는 `art_src/generated/pixellab/chars/act1_<이름>_v1.png`에 떨어진다.

## E. 반입 후 작업 (아트 세션에서 처리)

1. pixellab/_incoming/ 에서 받아 art_src/generated/pixellab/chars/ 로 snake_case 이름으로 옮긴다
2. East 프레임을 가로 스트립 png로 구워 assets/sprites/enemies/ 에 넣는다 (기존 dokkaebi_*_e.png 형식과 동일, 프레임 폭 = 캔버스 폭)
3. SpriteFrames .tres 를 개체별로 만든다 (scenes/enemies/{thief,egg,porter}_frames.tres)
4. 각 씬의 BodyVisual sprite_frames 를 교체하고 scale 을 1.0 으로 되돌린다
5. 자리표시 Polygon2D 노드를 제거한다 (Bundle, BundleKnot, EggBody, EggShade, EggBlotch, CargoVisual, CargoStrap)
6. 요청서 이 절과 docs/PROGRESS.md 에 반입 기록을 남긴다
