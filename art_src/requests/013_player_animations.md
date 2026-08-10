# 에셋 요청서: 013 플레이어 핵심 4동작 애니메이션

> 폐기 (2026-08-03): 아래 구르기(roll) 관련 작업은 모두 폐기되었다. 총 든 픽셀 캐릭터로 앞구르기를 안정적으로 만들 수 없어 구르기 기능 자체를 삭제하고 대시를 완전 회피로 통합했다. 아래 내용은 작업 이력으로만 보존한다.

작성: 2026-08-03 (A1 세션)
목적: 플레이어 모션 부재 해결. 걷기/공격/피격이 뻣뻣하다는 지적 반영
근거: DECISIONS 2026-08-03 게임필. 사용자 판정 "핵심 4동작"

## 대상 캐릭터

- 플레이어 v3 "modern korean young office worker" (id 06d81a93-88be-43a4-9a89-693667874155, 46px, 92x92 캔버스)

## 4동작 (PixelLab Character 애니메이션)

| 동작 | 방식 | 프레임 | 게임 상태 매핑 |
|---|---|---|---|
| Idle | V3 템플릿 | - | State.MOVE + 정지, 바닥 |
| Running | V3 템플릿 | 8 | State.MOVE + 이동, 바닥 |
| 사격 | Custom V3 "raising the rifle to shoulder and firing forward with a small recoil kick" | 6~7 | attack_ranged 입력 (별도 오버레이 또는 상체) |
| 피격 (Taking Punch) | Standard Reactions | 6 | _on_player_hit |

- 사이드뷰 게임이라 East 방향이 주력. West는 flip_h. South는 자동 생성분(참고용)
- 생성 방식: Generate in Background로 큐 등록. 각 방향은 East를 개별 트리거해 확보
- 2026-08-03 4동작 등록 완료. South 프레임 확인(사격 발사 포즈, 피격 젖힘 포즈 정상). East 큐 생성 진행 중

## Godot 연결 계획 (요청서 병행)

- BodyVisual을 Sprite2D -> AnimatedSprite2D로 교체, SpriteFrames 리소스에 4 애니메이션 등록 (idle, run, shoot, hurt)
- player.gd에 _update_animation(): 상태 + 이동 여부로 재생 클립 선택. 사격/피격은 원샷 후 복귀
- East 프레임을 기준으로 West는 flip_h. 프레임 크기는 트림 후 실측(46px 기준)
- 애니메이션 없는 클립은 정지 프레임 1장으로 폴백해 에러 방지

## 판정 기준

- [ ] Idle 미세 호흡으로 정지 시 살아있음
- [ ] Running이 이동 속도와 위화감 없이 맞물림 (발 미끄러짐 최소)
- [ ] 사격 시 반동 킥(코드)과 프레임이 겹쳐 타격감
- [ ] 피격 프레임이 화면 흔들림/점멸(코드)과 동시에 재생
- [ ] 스타일 일관 (기존 정지 스프라이트와 팔레트/비례 동일)

## 결과

- 2026-08-03 4동작 생성과 Godot 연결 완료:
  - Export: chars/player_anim/ (Idle/Running/Taking_Punch/raising_the_rifle... 각 east 8/8/6/7 프레임)
  - 에셋화: East 프레임을 공통 크롭(50x51)으로 정규화해 가로 스트립 시트 4장 -> assets/sprites/player/anim/player_{idle,run,shoot,hurt}_e.png
  - SpriteFrames: scenes/player/player_frames.tres (idle 6fps loop, run 12fps loop, shoot 15fps 1회, hurt 13fps 1회. AtlasTexture region 방식)
  - player.tscn: BodyVisual을 Sprite2D -> AnimatedSprite2D 교체 (position y -21, autoplay idle)
  - player.gd: _update_animation()으로 정지/이동 클립 자동, _play_oneshot()으로 사격/피격 원샷 + 잠금. West는 flip_h. 사망 시 hurt 정지, respawn 시 idle 복귀
  - tools/check.py 통과. 미리보기 GIF: previews/player_run.gif, player_shoot.gif
- 2026-08-03 인게임 판정 교정 (사용자 지적 4건):
  - 사격 방향 반대: PixelLab East 사격이 총구를 West로 생성. player_shoot_e.png를 프레임별 좌우 반전해 총구가 정면(East) 향하게 수정
  - 점프 밋밋함(공중부양): _tick_body_stretch로 상승 시 세로 스트레치(0.82,1.2), 낙하 시 눌림(1.14,0.88), 착지 스쿼시(1.22,0.78) 추가
  - 구르기 찌그러짐: _process_roll에서 진행 방향 1회전(rotation TAU)으로 굴러가는 표현
  - 대시 무표현: 대시 중 늘림(1.32,0.82) + 반투명 청색 잔상(0.03초 간격, 0.18초 페이드)
- 2026-08-03 사격/구르기 전용 프레임 재생성 (사용자 지적: 사격이 발차기, 구르기가 코드 회전):
  - 잘못된 사격(raising the rifle, recoil kick이 발차기로 해석됨) 삭제. Custom V3 재생성 "standing still and shooting a rifle straight forward, muzzle pointing forward, no kicking" (9프레임). 총을 어깨에 대고 정면 발사 + 총구 섬광. 방향 정상(반전 불필요)
  - 구르기 신규 생성: Custom V3 "fast forward combat roll, tucking into a ball, rolling forward, rising up" (9프레임). 실제 웅크려 구르는 모션
  - 재에셋화: 5개 애니메이션 공통 크롭 57x51(섬광 포함 폭 증가)로 통일. player_frames.tres에 roll 클립 추가(16fps 1회). shoot 9프레임 교체
  - player.gd: 구르기 회전 코드 제거 -> _change_state에서 roll 클립 재생. _update_animation이 ROLL/DASH 중 클립 유지. 사격은 파일 자체가 정상 방향이라 코드 flip 없음
  - tools/check.py 통과. GIF: previews/player_shoot.gif, player_roll.gif
- 잔여: 발 미끄러짐(run 속도) 튜닝, 대시 전용 프레임(선택), 적 2종 동일 방식 적용(다음)

## 캐릭터 전면 재생성 (2026-08-03, 총 든 전투 자세)

배경: 기존 캐릭터는 총을 옆/등에 내려 두어 매 사격마다 드는 전환이 필요했다. 이것이 사격 타이밍(자세 취하기 전 발사), 연사 시 총을 들었다 내림, 재장전 모션 부재, 구르기 초입만 재생의 공통 원인이었다. 사용자 판정 "캐릭터 전면 재생성".

- 신규 캐릭터: PixelLab id 762b71f3 (64x64, sidescroller). description에 "holding an old hunting rifle with both hands raised and aimed forward in a ready combat stance" 명시
- 6클립 East 확보(West 자동 미러): idle(조준 정지), running(총 든 달리기, 9), firing(조준-발사-유지, 7), reloading(허리춤 탄창 교체, 9), Taking Punch(6), combat roll(웅크림-구르기-조준 복귀, 9)
- 프레임 선별(조준 유지 구간만): idle=firing f6, run=running f4~8(5), shoot=firing f3~6(4), reload/hurt/roll 전체. 각 클립의 앞쪽 "총 드는 전환 프레임"은 제외해 항상 총을 든 상태를 유지
- 에셋화: 64x64 원본 프레임을 크롭 없이 그대로 가로 스트립(프레임 간 앵커 흔들림 방지). assets/sprites/player/anim/player_{idle,run,shoot,reload,hurt,roll}_e.png
- player_frames.tres 재작성: reload 클립 추가. speed idle 5 / run 14 / shoot 20 / reload 8 / hurt 14 / roll 16. region 64x64
- player.tscn: BodyVisual position.y -21 -> -16 (64px 캔버스 발 기준선)
- player.gd 교정:
  - 사격 타이밍: shoot 클립 첫 프레임이 이미 조준 자세라 발사 순간 자세가 일치. shoot 잠금 0.28 -> 0.2로 줄여 연사(fire_interval 0.16) 중 조준 유지
  - 재장전 모션: rifle.reload_started 연결. _on_reload_started가 reload 클립을 reload_time(1.1s)만큼 재생
  - 구르기: roll_duration 0.34 -> 0.5625(9프레임 16fps 전체 재생), roll_speed 250 -> 200, 무적창 0.08~0.45. 초입만 보이던 문제 해소
- 원본 보관: chars/char_player_v4/, chars/char_player_v4.zip
- tools/check.py 통과. 미리보기: previews/player_new_{idle,run,shoot,reload,hurt,roll}.gif
- idle은 조준 정지 1프레임(미세 호흡 없음). 생동감이 필요하면 조준 자세 idle 애니메이션 별도 생성 예정
- 인게임 검증(Mac Godot) 필요: 아래 항목

### 재생성 인게임 검증 항목 (Mac Godot)

- [ ] idle: 총을 앞으로 든 조준 자세로 정지해 있는가
- [ ] 이동: 총을 앞으로 든 채 달리는가 (총을 내렸다 드는 반복이 없는가)
- [ ] 사격: 총구가 정면을 향하고 발사와 조준 자세가 동시인가 (자세 취하기 전 발사 없음)
- [ ] 연사(K 유지): 총을 계속 든 채 반동만 반복되는가 (들었다 놨다 하지 않는가)
- [ ] 재장전(R): 총을 세워 허리춤 탄창을 교체한 뒤 조준으로 복귀하는 모션이 보이는가
- [ ] 구르기(L): 웅크려 완전히 구른 뒤 일어나 조준하는 전체 모션이 재생되는가 (초입에서 끊기지 않는가)
- [ ] 구르기 거리: 구르는 거리가 과하거나 부족하지 않은가 (roll_speed 200, duration 0.5625 튜닝 지점)
- [ ] 발 위치: 캐릭터 발이 발판/바닥에 정확히 닿는가 (BodyVisual position.y -16 적정 여부)
- [ ] 피격: 젖혀지는 피격 프레임이 화면 흔들림/점멸과 함께 재생되는가
- [ ] 방향 전환: 왼쪽 이동 시 총구와 몸이 왼쪽을 향하는가 (flip_h)

## 파지 자세 재생성 + 근접 총검 찌르기 추가 (2026-08-03)

배경: 견착(어깨에 대고 조준)이 기본이면 안 되고 첫 참조 이미지(러시아 군인)처럼 총을 몸 앞에 두 손으로 파지해야 한다는 지적. 구르기가 앞으로 기어가는 모습이라 잘못됨(두 번째 참조 이미지의 앞구르기로 교체). 근접 공격으로 총검술 찌르기 신규 요청(세 번째 참조 이미지).

- 자세 변경: 애니메이션을 patrol carry(총을 몸 앞에 낮게 두 손 파지, 견착하지 않음)로 재생성. Custom V3에서 keep first frame을 끄고 파지 자세를 프롬프트로 명시. 캐릭터 id 762b71f3 유지
- 파지 기반 동작(East 확보, West 자동 미러):
  - idle: standing still in a patrol carry (8프레임, 미세 호흡)
  - run: running while holding the rifle low (8)
  - shoot: firing from a low patrol carry, 총을 어깨에 올리지 않고 앞으로 뻗어 발사 (원본 8프레임 중 f1~f7 사용)
  - roll: 진짜 앞구르기(웅크림-손 짚기-머리 넣고 공처럼 회전-일어서기, 8). 기존 기어가기 폐기
  - melee(신규): bayonet thrust, 앞발 내딛는 런지 + 무게중심 전진 후 복귀 (8)
- reload(9), hurt(6)는 기존 프레임 재사용
- 에셋화: 64x64 원본 프레임 그대로 스트립 7장. player_frames.tres를 7클립으로 재작성(melee 추가). speed idle6/run14/shoot20/reload8/hurt13/roll16/melee15
- 코드 교정:
  - 구르기 거리 절반: roll_speed 200 -> 100, roll_duration 0.5625 -> 0.5(앞구르기 8프레임 16fps), 무적창 0.08~0.4
  - 근접 총검 연결: _change_state가 MELEE 진입 시 melee 클립 재생, _update_animation이 MELEE 중 클립 유지. 이동 잠금은 기존 _process_melee(_apply_horizontal 0)로 제자리 정지. weapon_rifle melee_windup 0.06 -> 0.2(앞발 내딛고 찌르는 순간에 타격 판정), melee_recovery 0.34 유지(후딜)
- 원본 보관: chars/char_player_v5/, char_player_v5.zip. 미리보기 previews/player_v5_{idle,run,shoot,reload,hurt,roll,melee}.gif
- tools/check.py 통과

### 파지 재생성 인게임 검증 항목 (Mac Godot)

- [ ] 모든 자세가 견착이 아니라 총을 몸 앞에 파지한 형태인가 (idle, run, shoot 공통)
- [ ] 사격이 총을 어깨에 올리지 않고 앞으로 뻗어 발사하는가
- [ ] 앞구르기가 공처럼 말아 한 바퀴 구르는가 (기어가기가 아님)
- [ ] 구르기 이동 거리가 이전의 절반 수준인가 (roll_speed 100 튜닝 지점)
- [ ] 근접(J): 앞발을 내딛어 무게중심이 앞으로 갔다가 복귀하는가, 찌른 뒤 후딜이 있는가
- [ ] 근접 중 좌우 이동이 잠기는가 (제자리 유지)
- [ ] 근접 타격 판정이 총검이 앞으로 뻗는 순간에 걸리는가 (melee_windup 0.2 튜닝 지점)

## 구르기 앞구르기 재구현: 웅크림 프레임 + 코드 회전 (2026-08-03)

배경: PixelLab 순수 프레임 앞구르기(8프레임)가 인게임에서 회전이 프레임 사이마다 끊기고, 스프라이트 앵커가 발에 있어 회전축이 어긋나 어색했다. AI 특성상 사이드뷰에서 몸이 완전히 뒤집히는 회전을 픽셀 프레임으로 안정적으로 못 만든다고 판단. 사용자 선택으로 하이브리드 방식 채택.

- 방식: 웅크린 공 프레임 1장(roll f6, 무릎을 안고 웅크린 자세, 가로세로 비율 0.96으로 가장 공에 가까움)을 회전용으로 쓰고, _process_roll에서 코드 회전으로 한 바퀴 굴린다
- 이전(v4)에 제거했던 코드 회전과 다른 점: 그때는 선 자세를 통째로 돌려 어색했다. 이번은 웅크린 공을 굴려 실제로 데굴 구르는 표현이며 2D 픽셀 게임 앞구르기의 표준 구현이다
- 구현:
  - player_roll_e.png = roll f6 1프레임. player_frames.tres의 roll 클립 1프레임으로 축소
  - _process_roll: rotation = (경과/duration) * facing * TAU (진행 방향으로 한 바퀴). 종료 시 rotation 0
  - _apply_state_squash가 MOVE/MELEE 진입 시 rotation 0으로 리셋(구르기 후 복귀 안전)
  - 회전축 정합: 초기엔 회전축이 캔버스 중앙(32,32)=웅크린 몸의 위쪽(등/목)에 걸려 어색했음. roll 프레임의 몸 중심(alpha bbox 중앙 33,35.5)을 캔버스 정중앙(32,32)으로 재정렬(-1,-4 shift)해, Godot 기본 회전축(스프라이트 중심)이 곧 웅크린 몸의 정중앙이 되도록 교정
  - roll_speed 100, roll_duration 0.5 유지(거리 절반)
  - 공 형태 보강(스쿼시): 총을 든 캐릭터라 PixelLab이 머리를 무릎에 파묻은 완전한 공을 못 만듦(무기 자세를 고수). 웅크림 프레임(f6)을 세로 0.7로 눌러(스쿼시) 회전시켜 더 둥근 공처럼 보이게 함. player_roll_e.png에 스쿼시가 구워져 있고 코드는 회전만 담당. _apply_state_squash가 ROLL 진입 시 잔여 스케일 초기화
  - 무기와 몸 동작 분리 원칙: 총은 여러 무기 중 첫 기본 무기일 뿐이므로, 구르기 같은 몸 동작을 총 기준으로 설계하면 안 됨. 완전한 공이 필요하면 무기 없는 맨몸 기준으로 만들어야 하며(손이 자유로워 무릎을 감쌀 수 있음), 이는 향후 무기 교체(검 등) 대응과도 직결. 현재는 스쿼시로 타협, 완전 공 비주얼은 추후 전용 도트로 다듬을 여지
- 미리보기: previews/player_v5_roll.gif (회전 시뮬)
- tools/check.py 통과

### 구르기 재구현 인게임 검증 항목 (Mac Godot)

- [ ] 웅크린 채 한 바퀴 데굴 굴러가는가 (프레임 끊김 없이 매끄러운 회전)
- [ ] 회전축이 몸통이라 제자리에서 구르며 앞으로 나아가는가 (발에 걸려 이상하게 돌지 않는가)
- [ ] 구르기가 끝나면 회전이 0으로 복귀해 선 자세로 돌아오는가
- [ ] 왼쪽 구르기 시 회전 방향이 반대(반시계)인가
- [ ] 회전 속도와 이동 거리가 자연스러운가 (roll_duration, roll_speed 튜닝 지점)

## 이동 모션 보강: 점프/낙하/벽 매달림/재장전+걷기 (2026-08-03)

배경: 점프감 부족(공중 전용 포즈 없이 코드 스쿼시만), 재장전 중 하체 차렷, 벽 매달림이 조준 포즈로 어색하다는 사용자 지적. docs/DECISIONS.md 2026-08-03 플레이어 모션 보강.

- 대상: 캐릭터 762b71f3(64x64). PixelLab Custom V3, East 방향만 생성(West는 flip_h)
- 생성 프롬프트(각 East):
  - jump: jumping upward off the ground, pushing off with the legs then rising, knees tucked, holding rifle low (9프레임)
  - fall: falling downward, legs extended slightly apart to land, holding rifle low (9프레임)
  - wall: clinging to a wall and sliding down, forearms and body pressed flat, knees bent (9프레임)
  - reload_run: running forward at full stride while reloading, hands changing magazine at waist (8프레임, keep-first-frame 해제)
- 채택 프레임(64x64 스트립): jump f2~4(3), fall f6~8(3), wall f4~7(4), reload_run 전체(8)
- 에셋: assets/sprites/player/anim/player_{jump,fall,wall,reload_run}_e.png. player_frames.tres에 jump(비순환 12fps), fall(순환 8), wall(순환 6), reload_run(순환 14)
- 코드: player.gd 점프/낙하 클립 선택, _wall_sliding 상태와 wall 클립, 재장전 2클립(reload/reload_run) 전환, 공중 왜곡 축소. 원본 ZIP은 art_src/generated/pixellab/modern_korean_young_office_worker.zip
- 미리보기: previews/player_{jump,fall,wall,reload_run}.gif

### 이동 모션 인게임 검증 항목 (Mac Godot)

- [ ] 점프: 상승 시 도약 포즈가 보이고 밋밋하지 않은가 (착지 시 스쿼시 유지)
- [ ] 낙하: 하강 시 낙하 포즈로 바뀌는가
- [ ] 재장전 정지: 제자리 재장전 모션(reload)이 보이는가
- [ ] 재장전 이동: 재장전 중 좌우 이동 시 하체가 걷고(reload_run) 감속(0.7배)되는가
- [ ] 벽 매달림: 벽에 붙어 하강 시 벽을 향해 팔을 뻗은 매달림 포즈로 미끄러지는가 (조준 포즈가 아님)
- [ ] 벽 방향: 좌/우 벽 각각에서 캐릭터가 벽 쪽을 바라보는가 (flip_h)
- [ ] 벽 점프: 벽에서 튀어 오를 때 점프 포즈로 전환되는가
- [ ] 피격: 재장전 중 피격 시 피격 반응이 재장전 클립보다 우선 재생되는가
