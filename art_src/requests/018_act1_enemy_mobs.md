# 에셋 요청서: 018 1막 잡몹 5종 캐릭터와 모션 세트

작성: 2026-08-04
갱신: 2026-08-04 (모션 세트 표준, 예고 신호와 반응 윈도우 표준, 잡도깨비 예고형 돌진 결정 반영)
갱신: 2026-08-04 (톤앤매너 v2 개정에 따른 중지 공지 추가. 요청서 019 선행)
목적: 1막 확정 잡몹 5종의 캐릭터 스프라이트와 전투 모션 전체를 제작한다. 각 유닛은 대기, 이동, 공격, 피격에 개성별 특수행동까지 채운다
근거 문서: docs/act1/ENEMIES.md 5장(확정 5종 상세)과 1장(반응 가능성 우선), docs/ART_STYLE.md 2장(SD 비례, 검정 아웃라인)과 7장(혼합 애니메이션), reference/act1_dokkaebi(도깨비 고증)
선행 기준: 잡도깨비 v4(char_dokkaebi_v4, id a3fdc4e0)를 잡몹 스타일 앵커로 삼는다. 남보라 피부, 난색 눈, 검정 아웃라인, 도구 반변신 원형을 5종 전체에 일관 적용한다
중지 공지 (2026-08-04): 캐릭터 톤앤매너 전면 개정(DECISIONS 2026-08-04)으로 이 요청서의 화풍 기준(chibi 비례, 검정 아웃라인, v4 앵커)은 폐기 예정이다. 요청서 019의 잡도깨비 채택본이 새 잡몹 앵커가 되며, 그 후 이 요청서의 프롬프트를 새 톤 기준으로 갱신해 5종을 재생성한다. 모션 세트(A), 예고 신호와 반응 윈도우 표준(B), 클립 정의(D)는 유효하다

## A. 모션 세트 표준 (2026-08-04 사용자 결정)

모든 유닛은 아래 공통 4모션에 개성별 특수행동을 더한다. 특수행동은 유닛의 역할과 문화 원형을 드러내는 판별 모션이다.

| 유닛 | 대기 | 이동 | 공격 | 피격 | 특수행동 |
|---|---|---|---|---|---|
| 잡도깨비 | idle | hop(깡충) | attack(근접 휘두르기) | hurt | charge(예고형 돌진) |
| 등불 도깨비 | idle(부유) | drift(부유 이동) | throw(등불알 투척) | hurt | evade(도약 이탈) |
| 장물아비 | idle | run(질주) | snatch(낚아채기) | hurt | flee(도주), dig(땅 파기 이탈) |
| 씨름꾼 | idle | hop_move(도약 접근) | grab(그랩) | hurt/stun | stance(씨름 자세 예고), charge(도약 돌진), throw(배지기) |
| 달걀도깨비 | idle | roll(구르기, 이동 겸 접촉) | (roll 접촉이 공격) | bounce(튕김) | vibrate(구르기 예고) |

- 잡도깨비는 기존 4모션(idle, hop, attack, hurt)이 있고 이번에 charge(예고형 돌진)를 추가한다
- 달걀도깨비는 공격 판정이 없고 구르기 접촉이 위협이라 별도 attack 클립 대신 roll이 이동과 공격을 겸한다

## B. 예고 신호와 반응 윈도우 표준 (2026-08-04 사용자 결정)

핵심 원칙: 모든 공격은 플레이어가 반응할 시간을 준다. 도전보다 반응 가능성을 우선한다 (ENEMIES 1장).

예고 신호 방식 (사용자 결정: 색 대신 부위 하이라이트 + 음)

- 색이 아니라 공격 부위의 형태와 밝기 변화로 예고한다. 예: 휘두르기 직전 팔과 무기 부위를 밝게 띄우고 크게 치켜든 실루엣을 만든다, 돌진 직전 다리 부위를 밝히고 웅크린다
- 예고 사운드를 병행한다. 공격 종류별로 구분되는 짧은 예고음(휘두르기, 돌진, 투척, 그랩)을 windup 시작에 재생한다
- 적색은 사용하지 않는다. 적색은 데스매치(생기 몰림) 전용 신호로 예약되어 있다 (DESIGN_ACT1 2장, ENEMIES 3장). 평시 예고에 적색을 쓰면 데스매치 신호가 희석된다
- 데스매치 시에는 눈과 환경이 지속 적색으로 바뀌고, 그 위에 평시와 동일한 부위 하이라이트 예고가 겹친다. 두 신호는 색(적색 지속)과 방식(부위 밝기 점멸)으로 구분된다

반응 윈도우 (프레임 타이밍)

- 예비동작(windup)은 ENEMIES 5장 표를 기준으로 하되 반응 임계(초안 0.23초, 14프레임 이상)를 밑돌지 않는다. 밑도는 값은 상향한다
- 애니메이션은 예비를 길게, 타격을 짧고 강하게, 후딜을 무게 있게 배분한다 (ART_STYLE 7장 키포즈 우선). 예비 키포즈는 크고 느리게 만들어 눈으로 읽히게 한다
- 데스매치에서도 예비 타이밍은 단축하지 않는다. 배율은 피해에만 적용한다 (ENEMIES 3장)

잡도깨비 돌진 결정 (사용자 결정: 예고형 돌진 유지)

- 현재 게임의 잡도깨비 돌진은 너무 빨라 대응이 어렵다. 이를 예고형으로 개편한다: 돌진 전 웅크림 예비(부위 하이라이트 + 예고음)를 두고 돌진 속도와 발동을 늦춰 반응 가능하게 한다
- 이 결정은 ENEMIES 5.1의 "순수 근접, 돌진은 씨름꾼 이관" 서술과 어긋나므로 ENEMIES 5.1과 DECISIONS.md를 갱신한다 (docs 반영 별도)
- 씨름꾼의 도약 돌진과 구분: 씨름꾼은 씨름 자세를 선행한 뒤 크게 도약하는 공간 제압형, 잡도깨비는 짧고 낮은 지상 돌진으로 근접 압박의 변주다

## 공통 생성 설정

- 도구: Character creator v3(sidescroller camera). 8방향 자동 생성, 사이드뷰 사용분은 East/West(West는 East 미러)
- 애니메이션: Custom V3 프롬프트로 개체 고유 동작 생성. East 개별 트리거로 확보. 제공 템플릿(Running, Taking Punch)은 이동/피격 기본형에 활용
- 라이팅: 플랫(알베도) 생성. 발광과 글로우는 굽지 않는다. 예고 하이라이트도 스프라이트에 굽지 않고 엔진(밝기 틴트, 파티클)이 얹는 것을 기본으로 하되, 예비 키포즈(부위를 크게 든 실루엣) 자체는 프레임에 담는다
- 고증 강제: 뿔, 오니, 고블린, 호피 무늬, 가시 철퇴 금지. 사람 형상 기반, 더벅머리 또는 패랭이, 한복

## C. 유닛별 규격과 베이스 생성 현황

| # | 유닛 | 씬 파일명 | 스프라이트/캔버스 | 베이스 상태 |
|---|---|---|---|---|
| 1 | 잡도깨비 | dokkaebi_grunt(enemy_charger) | 40px/76x76 | 완료 (char_dokkaebi_v4, id a3fdc4e0) |
| 2 | 등불 도깨비 | dokkaebi_lantern | 40px/72x72 | 생성 완료, 정합 양호 (id e22cb0e8) |
| 3 | 장물아비 | dokkaebi_thief | 40px/72x72 | 생성 완료, 정합 양호 |
| 4 | 씨름꾼 | dokkaebi_wrestler | 48px/96x96 | 생성 완료, 재생성 필요 (두 다리, 회갈색, 오거 인상) |
| 5 | 달걀도깨비 | dokkaebi_egg | 32px/52x52 | 생성 완료, 색 후보정/재생성 필요 (창백한 색, 상단 돌기) (id 6661f54d) |

재생성 프롬프트 조정 (베이스)

- 씨름꾼: 씨름 고증 강제(스모 아님). 옷 착용(한복 하의+상의), 샅바(허리와 허벅지), 잡기 자세, 무기 없음, 남보라 피부, 더벅머리(상투/촌마게 금지). 일본 요소 전면 배제(sumo, mawashi, topknot, chonmage, samurai, kimono). 두 다리 허용(v3 템플릿이 외다리 불가). 2026-08-04 사용자 교정
- 달걀도깨비: 남보라 명시("dusky indigo-violet purple color, NOT pale, NOT pink"), 매끈함 강조("perfectly smooth round egg, no bumps, no ears, no arms")

## D. 유닛별 프롬프트와 애니메이션 클립

각 클립은 East 생성, West 미러. 프레임 수는 잡적 저프레임 스냅 기준(4~9). windup은 B의 반응 임계를 지킨다.

### 1. 잡도깨비 dokkaebi_grunt

베이스 완료. 기존 4클립(idle, hop, attack, hurt) 유지. 추가 클립만 생성한다.

| 클립 | 방식 | 프레임 | 동작 서술 | 예고 |
|---|---|---|---|---|
| charge | Custom V3 | 8~9 | crouching low then a short quick ground dash forward, then recover | 웅크림 예비 프레임을 크게. 다리 부위 하이라이트 + 예고음. 돌진 속도는 코드에서 하향 |
| claw(선택) | Custom V3 | 6~8 | two fast raking swipes forward | 밀착 압박 변주. 필요성은 M1 체감 후 |

### 2. 등불 도깨비 dokkaebi_lantern (id e22cb0e8)

프롬프트:

```
korean dokkaebi wisp spirit floating low in the air, faint translucent lower
body trailing off into wisps instead of legs, holding a small round paper lantern
in one hand, wild shaggy mane hair, wide glowing warm orange eyes, small bamboo
paeraengi hat, dusky indigo-violet skin, tattered dark purple hanbok, chibi
proportions, small pixel art character, black outline, muted subdued night colors,
flat shading, no baked glow, NO horns, NO oni, NO goblin
```

| 클립 | 프레임 | 동작 서술 | 예고 |
|---|---|---|---|
| idle | 6~8 | floating and bobbing gently, holding the lantern | - |
| drift | 6 | slowly floating sideways to reposition | - |
| throw | 8~9 | winding up and hurling the round lantern ball forward in an overhand arc | 투척 팔과 등불알 부위를 밝게, windup 24f 이상 + 예고음. 착탄 마커는 코드 |
| evade | 6 | a quick short upward hop to reposition away | 회피 기동(무피해) |
| hurt | 6 | recoiling from a hit | - |

### 3. 장물아비 dokkaebi_thief

프롬프트:

```
nimble quick korean dokkaebi thief spirit, carrying a bulging cloth loot bundle
(bojagi sack) tied on its back, sly mischievous grin, wild shaggy hair, small
bamboo paeraengi hat, dusky indigo-violet skin, tattered dark hanbok with sleeves
rolled up, one hand outstretched ready to snatch, lean light build, chibi
proportions, small pixel art character, black outline, muted subdued colors,
flat shading, NO horns, NO oni, NO goblin
```

| 클립 | 프레임 | 동작 서술 | 예고 |
|---|---|---|---|
| idle | 6 | standing alert, clutching the loot bundle, shifty | - |
| run | 8 | running fast forward | - |
| snatch | 8 | a quick lunge reaching one hand forward to snatch, then pulling back | 뻗는 손 부위 하이라이트, windup 20f + 예고음 |
| flee | 8 | running away in a panic, clutching the bulging sack, no attack | 2국면 도주 |
| dig | 8~9 | crouching and frantically digging into the ground to escape | 큰 예비 모션 자체가 경고. 마지막 처치 창 |
| hurt | 6 | recoiling from a hit | - |

### 4. 씨름꾼 dokkaebi_wrestler (베이스 재생성 후)

프롬프트(재생성 반영):

```
korean dokkaebi spirit doing ssireum korean traditional wrestling,
dusky indigo-violet purple dokkaebi skin (not human skin tone),
wild shaggy messy loose mane hair down (NOT a topknot, NOT a bun, NOT a samurai chonmage),
wide glowing warm orange eyes, mischievous face, wearing knee-length hanbok pants
and a rolled-up short jacket, a pale ochre satba cloth belt around the waist and one thigh,
sturdy build, crouching low in a ssireum grappling stance, both hands open, empty hands
no weapon, chibi 2.5 head proportions, pixel art character, black outline, muted subdued
colors, flat shading, korean not japanese, NO sumo, NO mawashi, NO topknot, NO chonmage,
NO samurai, NO kimono, NO horns, NO oni, no tiger stripes, no spiked club, no mace
```

| 클립 | 프레임 | 동작 서술 | 예고 |
|---|---|---|---|
| idle | 6 | balanced on one leg, breathing | - |
| hop_move | 6~8 | hopping forward on one leg to approach | - |
| stance | 6~8 | dropping low into a ssireum ready crouch, arms spread | 모든 공격의 선행 예고. 가장 크고 읽기 쉬운 실루엣 |
| charge | 8~9 | crouch then an explosive one-legged hop dash forward | 씨름 자세 후 다리 부위 하이라이트 + 예고음 |
| grab | 8 | reaching out both arms to grab and clinch forward | 손 부위 하이라이트, windup 32f 슈퍼아머 |
| throw | 8~9 | a ssireum hip-throw, hoisting and tossing forward | 그랩 성공 연계 |
| stun | 6 | dazed and staggering after crashing | 충돌 STUN. 반격 창 |
| hurt | 6 | recoiling, favoring the weak left leg | 왼다리 약점 |

용처 추가 (2026-08-06, G9 씨름 이벤트)

씨름꾼 조형은 전투방 잡몹 외에 씨름 이벤트(docs/act1/EVENTS.md 5장 N5)의 대전 상대로도 쓴다. 지금은 스프라이트가 없어 잡도깨비로 대신하고 있으며, 나오면 resources/minigames/ssireum/의 .tres 3종에서 frames_path만 채우면 붙는다.

이벤트가 쓰는 클립은 위 표에서 idle, stance, grab, hurt다. 이벤트 전용으로 두 클립이 더 필요하다.

| 클립 | 프레임 | 동작 서술 | 용처 |
|---|---|---|---|
| clinch | 4~6 | 샅바를 맞잡고 버티는 대치 자세. 좌우로 조금씩 밀린다 | 대결 구간 전체. 가장 오래 보이는 자세다 |
| win | 6 | 이기고 뽐내는 자세. 폴짝 뛰거나 팔을 든다 | 플레이어 패배 시 |

또 큰 도깨비(황소만 한 장정)는 중간보스 씨름 장사 황소(docs/act1/MIDBOSS.md 3.2)의 축소판이다. 지금은 씨름꾼 조형을 2배로 키워 쓸 계획이며, 별도 조형이 필요한지는 중간보스 아트 세션에서 판단한다.

### 5. 달걀도깨비 dokkaebi_egg (id 6661f54d, 색 후보정/재생성 후)

프롬프트(재생성 반영):

```
korean egg dokkaebi (dalgyal dokkaebi), perfectly smooth round egg-shaped body,
dusky indigo-violet purple color, NOT pale NOT pink, faint warm speckles, no arms
no legs no ears no bumps, tiny faint dot eyes, blank expressionless surface, rolls
along the ground, small simple pixel art object, thick black outline, muted colors,
flat shading, NO horns, NO oni, NO goblin, no face details
```

| 클립 | 프레임 | 동작 서술 | 예고 |
|---|---|---|---|
| idle | 4~6 | sitting still, an occasional tiny jiggle | - |
| vibrate | 6 | trembling and vibrating in place, about to roll | 구르기 예고. 진동 + 예고음. windup 14f 이상 |
| roll | 4~8 (또는 단일 프레임+코드 회전) | rolling forward along the ground | 이동 겸 접촉 위협 |
| bounce | 6 | bouncing back and wobbling, stunned | 벽 충돌 튕김. 반격 창 |

- roll은 플레이어 구르기처럼 단일 웅크림 프레임 + 코드 회전이 안정적일 수 있다(둥근 형체라 회전 정합 유리). 순수 프레임 roll과 비교 후 채택

## E. Godot 연결 계획 (생성 후)

잡도깨비 v4 방식을 표준으로 따른다 (PROGRESS 2026-08-03).

- 에셋화: East 프레임을 클립별 가로 스트립 시트로 정규화. assets/sprites/enemies/{유닛}_{클립}_e.png. 캔버스 원본 크기 유지 우선(앵커 흔들림 방지)
- SpriteFrames: scenes/enemies/{유닛}_frames.tres에 클립별 등록. idle 6fps loop, 이동 12fps loop, 공격 원샷
- 씬: BodyVisual을 AnimatedSprite2D로, position.y 발 기준 실측. 공통 트리(EnemyBase 상속)는 ENEMIES 9장
- 예고 신호 구현: WINDUP 진입 시 공격 부위 Sprite 밝기 틴트(또는 파티클) 온, 예고음 재생. 색은 적색을 쓰지 않는다. 데스매치와 별개 채널(self_modulate 대 별도 하이라이트 노드)
- 반응 타이밍: windup/active/recovery 프레임을 AttackPattern .tres의 export로 노출. 잡도깨비 돌진은 속도와 발동 지연을 하향 튜닝
- 스탯 데이터: resources/enemies/{유닛}.tres(EnemyStats). 수치 권위는 .tres. West는 flip_h

## F. 판정 기준

- 고증: 5종 전체 뿔/오니/고블린 없음. 남보라 몸 + 난색 눈, 검정 아웃라인
- 스타일 일관: 잡도깨비 v4 앵커와 팔레트/비례/아웃라인 동일
- 실루엣 구분: 5종이 서로, 그리고 플레이어와 실루엣만으로 구분
- 반응 가능성: 각 공격의 예비 키포즈가 크고 느려 눈으로 읽히는가. windup이 반응 임계 이상인가
- 예고 신호: 부위 하이라이트 + 예고음이 공격 직전에 나오는가. 적색을 쓰지 않는가
- 크기 위계: 씨름꾼 최대, 달걀도깨비 최소

## G. Windows 인게임 검증 항목

- 각 유닛 상태별 애니메이션 전환, 발 기준선, 부유체 부유 높이
- 예비동작 프레임과 ENEMIES 5장 타이밍 표 일치, 예고 신호(부위 하이라이트 + 음) 가독성
- 잡도깨비 돌진: 예고 후 돌진이 반응 가능한 속도인가(수정 전 대비)
- 씨름꾼 stance 선행 후 charge/grab 분기, 그랩 슈퍼아머
- 달걀도깨비 roll 회전 정합(코드 회전 채택 시)
- 데스매치 시 적색 지속 전환과 평시 예고(부위 하이라이트)의 구분

## 생성 진행 기록

- 2026-08-04 베이스: 등불(e22cb0e8, 양호), 장물아비(양호), 씨름꾼(재생성 필요), 달걀(6661f54d, 색 보정 필요) 생성. 잡도깨비는 기존 v4
- 다음: 씨름꾼/달걀 베이스 재생성 → 5종 애니메이션 클립 생성 → 에셋화와 Godot 연결
