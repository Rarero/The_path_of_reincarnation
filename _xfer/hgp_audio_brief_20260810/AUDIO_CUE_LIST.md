# hgp 사운드 큐 목록

작성일: 2026-08-10
범위: 1막 도깨비 시장 전체. 타이틀, 인트로, 허브 포함
기준 코드: 2026-08-10 시점 저장소

## 문서 사용법

### 우선순위

| 등급 | 뜻 |
|---|---|
| P0 | 없으면 게임이 무음처럼 느껴지는 핵심. 플레이어 조작 피드백과 주요 음악 |
| P1 | 1막을 완성으로 보이게 하는 데 필요. 적별 개성, 환경, 이벤트 |
| P2 | 후순위. 또는 콘텐츠 자체가 미구현이라 사운드보다 코드가 먼저 |

### 상태

| 표기 | 뜻 |
|---|---|
| 훅 있음 | 코드에 트리거 지점이 이미 존재한다. 재생 호출만 추가하면 된다 |
| 코드 선행 | 판정이나 시그널이 없어 코드 추가가 먼저 필요하다 |
| 기획만 | 콘텐츠 자체가 미구현이다. 문서에만 있다 |

### 변형

같은 큐가 짧은 간격으로 반복되면 단일 클립은 기계음처럼 들린다. 변형 열은 필요한 클립 개수다.
1이면 단일 클립이며, 루프는 별도로 표기했다.

### 트리거 위치 표기

`파일경로 :: 함수명` 형식이다. 행 번호는 코드 수정 시 어긋나므로 함수명으로 찾는다.

## 요약

| 분류 | 큐 수 | P0 | P1 | P2 |
|---|---|---|---|---|
| 1. 음악 (BGM) | 27 | 6 | 16 | 5 |
| 2. 앰비언스 | 20 | 2 | 15 | 3 |
| 3. 스팅어 | 17 | 7 | 9 | 1 |
| 4. 플레이어 | 54 | 22 | 29 | 3 |
| 5. 적 | 83 | 13 | 60 | 10 |
| 6. 보스 | 44 | 8 | 34 | 2 |
| 7. 미니게임 | 52 | 3 | 44 | 5 |
| 8. 신당, 권능, 이벤트 | 36 | 4 | 28 | 4 |
| 9. UI와 시스템 | 35 | 13 | 20 | 2 |
| 합계 | 368 | 78 | 255 | 35 |

보스 6.7절의 중간보스와 히든 보스 6종은 코드가 없어 큐를 확정하지 않았고 위 수에 넣지 않았다.
변형까지 세면 실제 제작해야 할 클립 수는 이보다 많다. 각 표의 변형 열을 참고한다.

최소 재생 가능 세트(P0 78종)의 목록은 부록 B에 따로 모았다.

---

# 1. 음악 (BGM)

전부 루프다. 별도 표기가 없으면 심리스 루프를 전제한다.

| 큐 ID | 장면 | 트리거 위치 | 성격 | 우선 | 상태 |
|---|---|---|---|---|---|
| bgm_title | 타이틀 화면 | scenes/ui/main_menu.gd :: _ready | 저승 접수청 문턱의 정적. 대금과 낮은 징 한 겹. 게임의 첫인상 | P0 | 훅 있음 |
| bgm_intro_life | 인트로 1~3페이지 | scenes/cutscene/intro.gd :: _show_page (page 0) | 이승. 현대 도시의 무미건조한 저역. 국악 요소 없음 | P1 | 훅 있음 |
| bgm_intro_death | 인트로 4~7페이지 | scenes/cutscene/intro.gd :: _go_next_page (page 3 이후) | 저승. 화이트 플래시 뒤 편성이 완전히 바뀐다. 허브 곡으로 이어진다 | P1 | 훅 있음 |
| bgm_hub | 허브 접수청 | scenes/hub/hub.gd :: _ready | 관공서처럼 늘어진 저승 접수청. 느린 아쟁, 종이 넘기는 리듬. 정적이고 사무적 | P0 | 훅 있음 |
| bgm_act1_explore | 1막 탐색 (전투 전) | scenes/levels/run_stage.gd :: _load_current_room | 시장 안을 걷는 저강도 장단. 타악 위주. 앰비언스와 경계가 흐릿해도 된다 | P0 | 훅 있음 |
| bgm_act1_combat | 1막 전투 | scenes/levels/room.gd :: _activate (GameEvents.room_combat_started) | 사물놀이 장단이 붙는 전투 본편. 꽹과리 중심. explore 위에 얹는 레이어 방식 권장 | P0 | 훅 있음 |
| bgm_act1_rage_l1 | 생기 몰림 1단계 | scenes/levels/room.gd :: _process (GameEvents.rage_stage_changed) | 전투 곡 위에 겹치는 타악 레이어. 등불이 적색으로 물드는 시점 | P1 | 훅 있음 |
| bgm_act1_rage_l2 | 생기 몰림 2단계 | 동상 | 층을 하나 더 얹는다. 압박 증가 | P1 | 훅 있음 |
| bgm_act1_rage_l3 | 생기 몰림 3단계 | 동상 | 최대 밀도. 방을 빨리 비우라는 압박 | P1 | 훅 있음 |
| bgm_shrine | 신당 | scenes/levels/room_shrine.gd :: _on_shrine_entered | 무속 정적. 요령과 잔향 긴 배음. 거리 소음이 빠진 공백감이 핵심 | P0 | 훅 있음 |
| bgm_event | 이벤트방 | scenes/levels/run_stage.gd :: _start_node_event (GameEvents.event_started) | 결과를 감춘 긴장. 목탁 같은 불규칙 타점 | P1 | 훅 있음 |
| bgm_gamble | 노름판 | scenes/levels/run_stage.gd :: _open_minigame (GAMBLE) | 등불 아래 노름판의 나른하고 끈적한 밤 가락 | P1 | 훅 있음 |
| bgm_ssireum | 씨름판 | scenes/minigame/ssireum_minigame.gd :: begin | 판이 열렸다고 알리는 느린 장구. 연타 구간에서 빨라진다 | P1 | 훅 있음 |
| bgm_ssireum_duel | 씨름 연타 구간 | scenes/minigame/ssireum_minigame.gd :: _advance_timer (Phase.DUEL) | 몰아치는 장구 위주 빠른 루프. 관중 함성과 물린다 | P1 | 훅 있음 |
| bgm_chase | 장물아비 추격 | scenes/minigame/chase_minigame.gd :: Phase.RUN | 숨 가쁘게 몰아치는 추격 루프. 발놀림에 맞춘 타악 중심 | P1 | 훅 있음 |
| bgm_chase_last_lamp | 추격 위기 레이어 | scenes/minigame/chase_minigame.gd :: _watch_events (hits == max_hits - 1) | 등불 하나만 남았을 때 얹히는 위기 레이어 | P2 | 코드 선행 |
| bgm_boss_dormant | 보스 대문 앞 대기 | scenes/bosses/dokkaebi_muneolgul.gd :: _tick_intro | 숨죽인 대문 앞의 저역 드론. 리듬 없음. 전투곡이 아니다 | P1 | 훅 있음 |
| bgm_boss_muneolgul_p1 | 문얼굴 1페이즈 | scenes/bosses/dokkaebi_muneolgul.gd :: start_encounter | 수문신 주제. 완고하고 무거운 타악. 태평소와 대북 | P0 | 훅 있음 |
| bgm_boss_muneolgul_p2 | 문얼굴 2페이즈 (체력 70퍼센트) | scenes/bosses/dokkaebi_muneolgul.gd :: _on_phase_changed | 문이 열리고 소환이 붙는 개문 국면. 층이 하나 더 얹힌 편성 | P1 | 훅 있음 |
| bgm_boss_muneolgul_p3 | 문얼굴 3페이즈 (체력 30퍼센트) | scenes/bosses/dokkaebi_muneolgul.gd :: _on_phase_changed | 배속 0.75와 적색 광폭에 맞춘 최고조 편성 | P1 | 훅 있음 |
| bgm_boss_bangmangi_p1 | 방망이 1페이즈 | scenes/levels/room.gd :: _activate (보스방) | 심술궂은 요술쟁이 주제. 경쾌하고 변덕스러운 리듬 | P1 | 훅 있음 |
| bgm_boss_bangmangi_p2 | 방망이 2페이즈 (체력 50퍼센트) | scripts/enemies/boss_base.gd :: _apply_phase | 난무 국면. 템포와 밀도를 올린 근접 압박 편성 | P1 | 훅 있음 |
| bgm_map_overlay | 지도 열람 | scenes/ui/node_map.gd :: open | 본곡을 눌러 덮는 열람 레이어. 종이 위 정적. 트리 정지 중이라 process_mode ALWAYS 필요 | P1 | 훅 있음 |
| bgm_midboss | 중간보스 | scenes/levels/run_stage.gd :: _scene_for_kind (MIDBOSS) | 전투곡의 격상판. 태평소가 얹힌다. 중간보스 5종은 씬 미구현 | P2 | 기획만 |
| bgm_shop | 상점 | run_map.gd 열거에 SHOP은 있으나 _scene_for_kind에 분기가 없다 | 흥정과 호객. 전용 방 구현 후 배정 | P2 | 기획만 |
| bgm_rest | 쉼터 | run_map.gd 열거에 REST는 있으나 분기 없음 | 잠깐의 숨 고르기. 전용 방 구현 후 배정 | P2 | 기획만 |
| bgm_run_result | 런 종료 화면 | scenes/ui/test_end_screen.gd :: open | 여운만 남는 단선율. 2막이 붙으면 폐기 예정인 임시 화면 | P2 | 훅 있음 |

---

# 2. 앰비언스

전부 루프다. 짧은 루프에 불규칙 원샷을 얹는 조합을 권장한다.

| 큐 ID | 장소 | 트리거 위치 | 성격 | 우선 | 상태 |
|---|---|---|---|---|---|
| amb_act1_street | 좌판 거리 | scenes/levels/bg_act1.gd :: rebuild (Preset.STREET) | 도깨비 야시장 전체 소음 베드. 1막의 기본 질감 | P0 | 훅 있음 |
| amb_act1_crowd | 군중 웅성거림 | scenes/levels/bg_act1.gd :: _spawn_crowd, _spawn_mid_customers | 알아들을 수 없는 군상. 한국어로 알아들리면 안 된다 | P1 | 훅 있음 |
| amb_act1_tavern | 주막 | scenes/levels/bg_act1.gd :: _spawn_props (tavern) | 국솥 끓는 소리, 술잔, 웃음. 배치된 방에서만 | P1 | 훅 있음 |
| amb_act1_ssireum | 씨름장 (배경) | scenes/levels/bg_act1.gd :: _spawn_ssireum_match | 구경꾼 함성과 모래 밟는 소리 | P1 | 훅 있음 |
| amb_act1_gambling | 노름판 (배경) | scenes/levels/bg_act1.gd :: _spawn_gambling_circle | 멍석 위 엽전과 투전 섞는 소리 | P1 | 훅 있음 |
| amb_act1_haggle | 좌판 흥정 | scenes/levels/bg_act1.gd :: _spawn_shoppers | 좌판 앞 흥정. 웅성거림보다 앞에 선다 | P1 | 훅 있음 |
| amb_act1_lantern | 등불 | scenes/levels/bg_act1.gd :: _spawn_prop_glows, _spawn_street_lights | 청사초롱 심지 타는 소리와 종이 떨림 | P1 | 훅 있음 |
| amb_act1_dokkaebi_fire | 도깨비불 | scenes/levels/bg_act1.gd :: _spawn_fires | 서늘한 화염 흔들림. 등불의 난색과 대비되는 한색 질감 | P1 | 훅 있음 |
| amb_act1_ember | 불티 | scenes/levels/bg_act1.gd :: _spawn_embers | 불티 떠오르는 가벼운 파열음. 성기게 | P2 | 훅 있음 |
| amb_act1_night_wind | 밤바람 (원경) | scenes/levels/bg_act1.gd :: _build_clouds, _build_ridges | 능선 너머 밤바람. 프리셋 무관 상시 베드 | P1 | 코드 선행 |
| amb_act1_roof | 지붕 위 | scenes/levels/bg_act1.gd :: rebuild (지붕 방 프리셋) | 시장 소음이 아래로 멀어진다. 바람이 전면에 온다. 문서상 인상은 고요와 개방 | P1 | 훅 있음 |
| amb_act1_alley | 골목 | scenes/levels/bg_act1.gd :: _spawn_alley_windows | 좁은 반향. 거리 소음이 벽 너머로만 들린다. 문서상 인상은 은밀과 압박 | P1 | 훅 있음 |
| amb_act1_gate | 귀문 근처 | scenes/levels/bg_act1.gd :: _spawn_props (gate) | 낮은 이명. 경계 밖의 기척 | P2 | 코드 선행 |
| amb_shrine_alley | 골목 신당 (권능) | scenes/levels/bg_act1.gd :: _build_shrine_backdrop (SHRINE_ALLEY) | 소박한 돌무더기 서낭당. 거리 소음이 멀다 | P1 | 훅 있음 |
| amb_shrine_seonang | 서낭당 신목 (몸주) | scenes/levels/bg_act1.gd :: _build_shrine_backdrop (SHRINE_SEONANG) | 신목 앞 바람과 오색천 나부낌. 격식 있는 사당 | P1 | 훅 있음 |
| amb_shrine_mote | 신기 티끌 | scenes/levels/bg_act1.gd :: _spawn_spirit_motes | 맑은 미세 울림. 호흡하듯 명멸. 신성 신호 음색 예약 대상 | P1 | 훅 있음 |
| amb_shrine_mist | 신당 안개 | scenes/levels/bg_act1.gd :: _spawn_shrine_mist | 한색 안개층. 거리 앰비언스를 눌러 서늘하게 만든다 | P2 | 훅 있음 |
| amb_hub_office | 허브 접수 홀 | scenes/hub/hub.gd :: _ready, _update_crowd | 민원 대기줄 웅얼거림, 도장 찍는 소리, 종이. 해금 수에 따라 군상이 늘어나므로 레이어 구조 권장 | P0 | 훅 있음 |
| amb_hub_storage | 특수창고 (좌측) | scenes/hub/hub.gd :: _ready | 먼지와 정적. 사망 반송 스폰 지점 | P1 | 코드 선행 |
| amb_boss_arena | 보스 대문 광장 | scenes/levels/room_boss_daemun_gwangjang.gd | 넓은 반향과 돌바람. 시장 소음이 사라진 개활지 | P1 | 훅 있음 |

---

# 3. 스팅어

짧은 전환 신호다. 음악 위에 겹치므로 음정 충돌을 피하도록 조성을 맞춘다.

| 큐 ID | 시점 | 트리거 위치 | 성격 | 우선 | 상태 |
|---|---|---|---|---|---|
| stg_run_start | 런 시작 (상행문 통과) | scenes/hub/hub.gd :: _try_depart | 상행문이 열리며 길이 트이는 출발 신호 | P0 | 훅 있음 |
| stg_room_enter | 방 진입 | scenes/levels/run_stage.gd :: _load_current_room | 짧은 타점. 방 종류별 변주 (전투, 이벤트, 신당) | P1 | 훅 있음 |
| stg_room_clear | 방 클리어 | scenes/levels/room.gd :: _finish (GameEvents.room_cleared) | 장단이 풀리며 해소되는 한 소절 | P0 | 훅 있음 |
| stg_wave_next | 다음 웨이브 | scenes/levels/room.gd :: _advance_waves | 밀려드는 예고 타격. 2번째 웨이브부터 | P1 | 훅 있음 |
| stg_rage_warning | 생기 몰림 경고 | scenes/levels/room.gd :: _emit_warning (GameEvents.rage_warning) | 불길한 상승음. 1초 단위 반복. 간격이 좁아지는 형태 | P0 | 훅 있음 |
| stg_rage_trigger | 생기 몰림 발동 | scenes/levels/room.gd :: _process (rage_stage_changed) | 판이 뒤집히는 파열. 등불이 적색으로 물드는 순간 | P0 | 훅 있음 |
| stg_event_start | 이벤트 진입 | scenes/levels/run_stage.gd :: _start_node_event | 알 수 없는 일이 시작되는 의문형 한 음 | P1 | 훅 있음 |
| stg_event_win | 이벤트 이득 | scenes/levels/run_stage.gd :: _on_minigame_finished (won) | 이득이 확정될 때의 밝은 등불 호박색 스팅어 | P1 | 훅 있음 |
| stg_event_lose | 이벤트 손실 | 동상 (won == false) | 손실이 확정될 때의 낮게 깔리는 남색 스팅어 | P1 | 훅 있음 |
| stg_boss_encounter | 보스 개전 | scenes/bosses/dokkaebi_muneolgul.gd :: start_encounter | 태평소 한 방으로 판을 여는 강타 | P0 | 훅 있음 |
| stg_boss_phase | 보스 페이즈 전환 | scripts/enemies/boss_base.gd :: _apply_phase | 정지와 재개. 전환 잠금 구간(무적) 동안 곡 사이를 잇는다 | P1 | 훅 있음 |
| stg_boss_defeat | 보스 처치 | scripts/enemies/boss_base.gd :: _on_died | 장대한 마무리. 이어서 정적 | P0 | 훅 있음 |
| stg_run_clear | 런 완주 | scenes/levels/run_stage.gd :: _finish_run | 여의주 조각이 손에 남는 여운 | P1 | 훅 있음 |
| stg_run_fail | 런 실패 (사망) | scenes/levels/run_stage.gd :: _on_player_died | 소멸. 모든 것이 빠져나가는 하강음. 음악을 끊고 정적으로 떨어뜨린다 | P0 | 훅 있음 |
| stg_intro_flash | 인트로 3페이지 충돌 | scenes/cutscene/intro.gd :: _go_next_page (flash_after) | 경적과 굉음 뒤 완전한 정적. 문서에 "빵" 명시 | P1 | 훅 있음 |
| stg_depletion | 명줄 소모 단계 상승 | scripts/map/run_map.gd :: depletion_stage | 명줄이 닳았음을 알리는 마른 경고 | P1 | 훅 있음 |
| stg_minigame_open | 미니게임 오버레이 | scenes/levels/run_stage.gd :: _open_minigame | 세상이 한 겹 멀어지는 짧은 휩쓸림. 방 소리를 눌러 두는 덕킹과 함께 | P2 | 훅 있음 |

---

# 4. 플레이어

## 4.1 이동

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_player_footstep | 달리기 발소리 | scenes/player/player.gd :: _update_animation (run 클립) | 저잣거리 흙바닥을 밟는 짧고 마른 발소리 | 4 | P0 | 코드 선행 (접지 프레임 훅 없음) |
| sfx_player_jump | 점프 | scenes/player/player.gd :: _jump | 발 구르며 도약하는 짧은 호흡과 옷깃 스침 | 3 | P0 | 훅 있음 |
| sfx_player_walljump | 벽 점프 | scenes/player/player.gd :: _try_jump (wall_dir 경로) | 벽을 차고 튕겨 나가는 둔탁한 반발음 | 2 | P0 | 훅 있음 |
| sfx_player_land | 착지 | scenes/player/player.gd :: _tick_body_stretch (_was_airborne 전이) | 가볍게 착지하며 눌리는 흙먼지 | 3 | P0 | 훅 있음 |
| sfx_player_land_heavy | 강한 착지 | 동상 (낙하 속도 분기 필요) | 높은 곳에서 떨어져 무릎이 꺾이는 무거운 충격 | 2 | P1 | 코드 선행 |
| sfx_player_wall_touch | 벽 붙기 | scenes/player/player.gd :: _try_wall_slide (false to true 전이) | 손바닥과 옷이 벽에 닿는 마찰 개시음 | 2 | P1 | 코드 선행 (전이 판별 없음) |
| sfx_player_wall_slide | 벽 미끄러짐 | scenes/player/player.gd :: _try_wall_slide (_wall_sliding 유지) | 벽을 긁으며 미끄러지는 지속 마찰 | 루프 1 + 꼬리 1 | P1 | 훅 있음 |
| sfx_player_dash | 대시 | scenes/player/player.gd :: _try_start_dash | 공기를 가르는 짧은 휙. 구르기는 폐지되어 대시로 통합되었다 | 3 | P0 | 훅 있음 |
| sfx_player_dash_fail | 대시 실패 (기력 부족) | scripts/components/stamina.gd :: spend (실패 반환) | 힘이 빠져 못 나가는 마른 헛숨 | 2 | P0 | 훅 있음 |
| sfx_player_dash_wall_stop | 대시 중 벽 충돌 | scenes/player/player.gd :: _after_move (대시 중 is_on_wall) | 벽에 처박혀 대시가 끊기는 둔탁한 정지 | 2 | P1 | 훅 있음 |
| sfx_player_drop_through | 원웨이 발판 통과 | scenes/player/player.gd :: _start_drop_through | 발판을 스르르 빠져 통과하는 나무 삐걱임 | 2 | P1 | 훅 있음 |

참고: 이단 점프는 설계상 존재하지 않는다. 공중 1회 제한은 대시와 점프 공격에만 있다.

## 4.2 근접 (환도)

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_melee_swing_1 | 1타 베기 | scripts/weapons/weapon_melee.gd :: _start_step (index 0) | 가볍고 빠른 칼바람. 시그널 `swung`은 주석에 사운드 훅으로 명시되어 있다 | 2 | P0 | 훅 있음 |
| sfx_melee_swing_2 | 2타 반대 베기 | 동상 (index 1) | 1타와 음정을 달리한 되돌려 베기 | 2 | P0 | 훅 있음 |
| sfx_melee_swing_3 | 3타 마무리 내려베기 | 동상 (index 2) | 무겁고 길게 끄는 내려베기. 피해 2배와 넉백이 붙는 마무리 | 2 | P0 | 훅 있음 |
| sfx_melee_air_swing | 공중 내려찍기 | scripts/weapons/weapon_melee.gd :: _try_jump_attack | 아래로 꽂는 하강 궤적감 | 2 | P0 | 훅 있음 |
| sfx_melee_hit | 근접 명중 | scripts/components/hitbox.gd :: _scan (hit_landed) | 살점과 뼈에 파고드는 젖은 타격음. 게임에서 가장 자주 들리는 소리 | 4 | P0 | 훅 있음 |
| sfx_melee_hit_finisher | 마무리 타 명중 | 동상 + combo_step 2 분기 | 저역이 실린 강한 파열과 넉백 | 2 | P0 | 훅 있음 |
| sfx_melee_whiff | 빗나감 | 별도 miss 판정 없음. 스윙음을 기본 레이어로 쓰는 편이 실용적 | 허공을 가르고 지나가는 얇은 잔향 | 3 | P2 | 코드 선행 |
| sfx_melee_dash_cancel | 공격 대시 취소 | scripts/weapons/weapon_melee.gd :: cancel_attack | 휘두르던 칼을 급히 거두는 짧은 금속 스침 | 1 | P1 | 훅 있음 |
| sfx_melee_land_recovery | 점프 공격 착지 후딜 | scripts/weapons/weapon_melee.gd :: notify_landed | 땅에 꽂힌 칼을 뽑는 무게감 | 2 | P1 | 훅 있음 |

## 4.3 원거리 (총)

`fire_interval`이 0.16초 연사라 반복이 매우 잦다. 발사음은 변형 4종을 최소로 본다.

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_rifle_fire | 발사 | scenes/player/weapon_rifle.gd :: try_fire | 화승총 계열의 마른 파열음 | 4 | P0 | 훅 있음 |
| sfx_rifle_fire_tail | 총성 잔향 | 동상 (후미 레이어) | 골목에 남는 반향 꼬리. 방 종류에 따라 잔향을 바꾸면 공간감이 산다 | 2 | P1 | 훅 있음 |
| sfx_rifle_last_round | 마지막 한 발 | scenes/player/weapon_rifle.gd :: try_fire (_ammo == 0) | 탄창이 비었음을 알리는 금속 튕김 | 1 | P0 | 훅 있음 |
| sfx_rifle_dryfire | 빈 격발 | scenes/player/weapon_rifle.gd :: try_fire (실패 반환) | 발사되지 않는 딸깍. auto_reload가 켜져 있어 재장전 중 입력이 주 사례 | 2 | P1 | 코드 선행 (실패 사유 시그널 없음) |
| sfx_rifle_reload_start | 장전 시작 | scenes/player/weapon_rifle.gd :: try_reload (reload_started) | 탄창을 빼고 화약을 재는 조작음. 수신부 `_on_reload_started`가 비어 있어 훅 자리가 그대로 있다 | 2 | P0 | 훅 있음 |
| sfx_rifle_reload_finish | 장전 완료 | scenes/player/weapon_rifle.gd :: _tick_reload (reload_finished) | 확실한 철컥. 조왕 불티 조건이 열리는 순간이라 가청성이 중요하다 | 2 | P0 | 훅 있음 |
| sfx_bullet_launch | 탄환 발사 | scenes/weapons/projectile.gd :: launch | 총성에 겹치는 비행 시작. 8방향 조준에 맞춘 팬 처리 | 2 | P1 | 훅 있음 |
| sfx_bullet_impact_flesh | 적 명중 | scenes/weapons/projectile.gd :: _on_area_entered | 짧고 습한 관통 | 3 | P0 | 훅 있음 |
| sfx_bullet_impact_wall | 지형 착탄 | scenes/weapons/projectile.gd :: _on_body_entered | 마른 도탄과 파편 | 3 | P0 | 훅 있음 |
| sfx_weapon_equip_hwando | 환도 뽑기 | scenes/player/player.gd :: _set_weapon_kind | 금속 마찰 | 1 | P1 | 훅 있음 |
| sfx_weapon_equip_rifle | 총 들기 | 동상 (RANGED) | 어깨에서 내려 자세를 잡는 나무와 쇠 소리 | 1 | P1 | 훅 있음 |

## 4.4 패링과 가드

패링 시스템 자체가 미구현이다. docs/systems/WEAPONS.md 7장에 설계는 완비되어 있고 7.2절에 사운드 규격 한 줄이 이미 있다.
"있다면 타격음과 확실히 구분되는 금속성 챙 소리 계열".

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_parry_success | 패링 성공 | docs/systems/WEAPONS.md 11장 설계 지점 (Projectile이 Hurtbox 접촉 직전 판정) | 타격음과 확실히 구분되는 금속성 챙. 문서가 이미 규격을 지정했다 | 3 | P1 | 기획만 |
| sfx_parry_ready | 패링 재준비 | 내부 쿨다운 0.5초 회복 시점 | 다시 받아낼 수 있다는 옅은 울림 | 1 | P2 | 기획만 |
| sfx_guard_blocked | 적 가드에 막힘 | scripts/components/guard_hurtbox.gd :: receive_hit (blocks_hit) | 짐꾼 도깨비 정면 가드에 튕기는 무효 타격. 명중음과 확실히 달라야 한다 | 3 | P0 | 훅 있음 |

플레이어 전용 가드 입력은 없다. project.godot의 `[input]`에 방어 액션이 없고, 방어는 패링과 대시 무적으로만 처리한다.

## 4.5 피격과 사망

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_player_hurt | 피격 | scenes/player/player.gd :: _on_player_hit | 짧게 삼키는 신음과 몸에 꽂히는 충격 | 4 | P0 | 훅 있음 |
| sfx_player_hurt_impact | 히트스톱 임팩트 | scenes/player/player.gd :: _hitstop | 히트스톱 0.05초에 얹는 저역 레이어 | 2 | P1 | 훅 있음 |
| sfx_player_knockback | 넉백 | scenes/player/player.gd :: _on_player_hit (velocity 대입) | 뒤로 밀려나며 미끄러지는 짧은 마찰 | 2 | P1 | 훅 있음 |
| sfx_player_death | 사망 | scenes/player/player.gd :: _on_died | 무너져 쓰러지는 몸과 떨어지는 무기. 화면 흔들림 4.0/0.3초와 동기 | 2 | P0 | 훅 있음 |
| sfx_lethal_guard_save | 치명타 방어 (유물) | scripts/components/health.gd :: apply_damage (lethal_guard 성공) | 군번줄이 죽음을 대신 받는 극적인 파열과 정적. 런에서 손꼽히는 순간 | 1 | P1 | 훅 있음 |
| sfx_player_heal | 회복 | scripts/components/health.gd :: heal | 상처가 아물며 숨이 트이는 따뜻한 회복음 | 2 | P1 | 코드 선행 (호출자가 전무하다) |
| sfx_player_health_low | 저체력 경고 | scenes/player/player.gd :: _on_health_changed | 맥동 루프. 임계값 판정이 없어 신설 필요 | 루프 1 | P1 | 코드 선행 |
| sfx_max_health_up | 최대 체력 상승 | scenes/player/player.gd :: _apply_run_bonuses | 그릇 자체가 커지는 묵직한 상승 | 1 | P1 | 훅 있음 |

## 4.6 자원과 상태이상

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_stamina_drain_all | 기력 전량 소모 (범의 이빨) | scripts/components/stamina.gd :: drain_all | 기력을 통째로 태우는 급격한 흡입 | 1 | P1 | 훅 있음 |
| sfx_burn_apply | 화상 부여 | scripts/systems/status_burn.gd :: apply | 불이 옮겨붙는 순간의 확 하는 점화 | 2 | P1 | 훅 있음 |
| sfx_burn_stack | 화상 중첩 | scripts/systems/status_burn.gd :: _add | 스택이 쌓일수록 음이 올라간다 | 3 (단계별) | P1 | 훅 있음 |
| sfx_burn_tick | 화상 피해 | scripts/systems/status_burn.gd :: _burn_once (1초 주기) | 지지는 짧은 피해음. 반복이 잦아 볼륨을 낮게 깔고 변형 필수 | 3 | P1 | 훅 있음 |
| sfx_burn_loop | 화상 지속 | status_burn 인스턴스 생존 구간 | 타는 동안 대상에 붙는 화염 루프 | 루프 1 | P1 | 훅 있음 |
| sfx_burn_expire | 화상 해제 | scripts/systems/status_burn.gd :: _clear | 사그라지는 잔불 | 1 | P2 | 훅 있음 |
| sfx_relic_hazelnut | 개암 한 알 (유물) | scenes/player/player.gd :: _stagger_nearby_enemies | 설정상 소리가 터져 적을 경직시키는 유물이라 사운드가 효과 본체다. 날카로운 파열과 충격파 | 2 | P1 | 훅 있음 |
| sfx_coin_gain | 엽전 획득 | autoload/run_state.gd :: add_coins | 엽전 몇 닢이 짤랑 | 3 | P0 | 훅 있음 |
| sfx_bell_gain | 무당 방울 획득 | autoload/run_state.gd :: add_bells | 방울 하나가 늘어나는 맑은 울림 | 1 | P1 | 훅 있음 |
| sfx_relic_gain | 유물 획득 | autoload/run_state.gd :: grant_relic_by_id, grant_random_relic | 낡은 물건을 집어 드는 마른 질감 | 2 | P1 | 훅 있음 |
| sfx_world_impact | 월드 충격 (공통) | autoload/game_events.gd :: screen_shake 수신 | 지진과 낙하 충격의 공통 저역. strength 값으로 3단계 매핑 | 3 (강도별) | P1 | 훅 있음 |
| sfx_fall_respawn | 낙사 복귀 | scenes/levels/run_stage.gd :: _recover_from_fall | 어긋난 되감김. 1막에는 낙사 즉사가 없다 | 1 | P1 | 훅 있음 |

---

# 5. 적

## 5.1 전 개체 공통

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_enemy_spawn | 등장 | scenes/levels/room.gd :: _spawn_wave | 방 슬롯에 적이 나타나는 짧은 등장 기척 | 3 | P0 | 훅 있음 |
| sfx_enemy_alert | 인지 | 문서상 ALERT 상태 (인지 지연 0.2~0.4초). 코드는 거리 비교만 있다 | 플레이어를 발견하고 몸을 돌리는 짧은 각성음 | 3 | P1 | 코드 선행 |
| sfx_enemy_step | 발소리 | scripts/enemies/enemy_base.gd :: walk_toward | 도깨비 맨발이 흙바닥을 밟는 가벼운 발소리 | 4 | P1 | 훅 있음 |
| sfx_enemy_hop_ledge | 단차 도약 | scripts/enemies/enemy_base.gd :: try_clear_obstacle | 폴짝 넘는 도약 기합 | 2 | P1 | 훅 있음 |
| sfx_enemy_break_prop | 장애물 파괴 | scripts/enemies/enemy_base.gd :: try_clear_obstacle (break_now) | 앞을 막은 좌판이 부서지는 나무 파열 | 3 | P1 | 훅 있음 |
| sfx_enemy_windup | 공격 예비 (공통) | scripts/enemies/enemy_pattern_actor.gd :: start_pattern | 숨 들이키는 텔레그래프. 반응 시간 하한 14프레임 안에서 판별 가능해야 한다 | 3 | P0 | 훅 있음 |
| sfx_enemy_swing | 공격 발동 (공통) | scripts/enemies/enemy_pattern_actor.gd :: _enter_active | 판정이 켜지는 순간의 휘두르기 파공음 | 3 | P0 | 훅 있음 |
| sfx_enemy_recover | 공격 후딜 (공통) | scripts/enemies/enemy_pattern_actor.gd :: _enter_recovery | 헛친 뒤 자세를 되돌리는 후딜 기척 | 2 | P2 | 훅 있음 |
| sfx_enemy_attack_land | 적 공격 명중 | scripts/components/hitbox.gd :: _scan | 적 공격이 플레이어에게 꽂히는 타격음 | 3 | P0 | 훅 있음 |
| sfx_enemy_hurt | 피격 | scripts/enemies/enemy_base.gd :: _on_hit_received | 짧게 지르는 비명. 적 종별로 음색이 갈린다 | 종별 3 | P0 | 훅 있음 |
| sfx_enemy_stagger | 경직 | scripts/enemies/enemy_base.gd :: _on_hit_received (can_be_staggered 참) | 뒤로 밀리며 발이 끌리는 소리 | 3 | P1 | 훅 있음 |
| sfx_enemy_hit_armored | 슈퍼아머 무효 | scripts/enemies/enemy_base.gd :: _on_hit_received (거짓 분기) | 밀리지 않고 튕겨 나오는 둔중한 무효 타격 | 3 | P1 | 훅 있음 |
| sfx_enemy_death | 처치 | scripts/enemies/enemy_base.gd :: _on_died | 흰 섬광과 함께 납작해지며 터지는 소멸음 | 3 | P0 | 훅 있음 |
| sfx_enemy_death_tool | 정체 폭로 | 문서상 처치 연출 (빗자루, 부지깽이, 절굿공이로 되돌아감). 코드에 없다 | 정체가 풀려 헌 도구가 바닥에 떨어져 구르는 소리 | 3 | P1 | 기획만 |
| sfx_enemy_kill_hitstop | 처치 히트스톱 | scripts/enemies/enemy_base.gd :: _kill_hitstop | 0.045초 히트스톱에 겹치는 저역 임팩트 | 2 | P1 | 훅 있음 |
| sfx_enemy_enraged | 생기 몰림 전환 | scenes/levels/room.gd :: _process (rage_stage_changed) | 눈이 적색으로 바뀌는 전환 신호 | 2 | P1 | 훅 있음 |

## 5.2 잡도깨비 (enemy_charger)

프로젝트에서 유일하게 오디오 노드가 배선된 개체다. `TelegraphSound`(AudioStreamPlayer2D)와 `telegraph_sound` export가 이미 있고 스트림만 비어 있다.

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_charger_patrol | 순찰 | scenes/enemies/enemy_charger.gd :: _patrol | 어수룩하게 통통 튀는 순찰 발걸음 | 3 | P1 | 훅 있음 |
| sfx_charger_approach | 접근 | scenes/enemies/enemy_charger.gd :: _approach | 속도가 흔들리는 불규칙한 접근 | 3 | P1 | 훅 있음 |
| sfx_charger_swing_windup | 근접 휘두르기 예비 (16f) | scenes/enemies/enemy_charger.gd :: _play_telegraph | 팔을 크게 치켜드는 예고 기합. 클립만 꽂으면 바로 난다 | 2 | P0 | 훅 있음 |
| sfx_charger_swing_active | 근접 휘두르기 | scenes/enemies/enemy_charger.gd :: _enter_active | 굵게 내리치는 한 방 파공음 | 2 | P0 | 훅 있음 |
| sfx_charger_claw_windup | 연속 할퀴기 예비 (15f) | 동상 | 짧고 빠른 밀착 압박 예고 | 2 | P1 | 훅 있음 |
| sfx_charger_claw_active | 연속 할퀴기 (2연타) | scenes/enemies/enemy_charger.gd :: _advance_phase | 두 번 갈라 긁는 가벼운 할큄음 | 2 | P1 | 훅 있음 |
| sfx_charger_dash_windup | 돌진 웅크림 (20f) | scenes/enemies/enemy_charger.gd :: _start_charge_windup | 힘을 모으는 돌진 예고. 회피 판단의 근거라 가장 중요한 예고음 | 2 | P0 | 훅 있음 |
| sfx_charger_dash_go | 돌진 개시 | scenes/enemies/enemy_charger.gd :: _start_charge | 튕겨 나가는 파열음 | 2 | P0 | 훅 있음 |
| sfx_charger_dash_loop | 돌진 중 (0.70초) | scenes/enemies/enemy_charger.gd :: _tick_charge | 질주 바람소리 | 루프 1 | P1 | 훅 있음 |
| sfx_charger_dash_end | 돌진 종료 | scenes/enemies/enemy_charger.gd :: _end_charge | 미끄러져 멈추는 착지음 | 2 | P1 | 훅 있음 |
| sfx_charger_bonk | 벽 충돌 | scenes/enemies/enemy_charger.gd :: _bonk | 머리를 박고 튕기는 우스꽝스러운 충돌음. 해학 표현이 허용되는 지점 | 2 | P1 | 훅 있음 |
| sfx_charger_bonk_recover | 어지러움 회복 | scenes/enemies/enemy_charger.gd :: _tick_bonk | 어질어질하다 정신을 차리는 기척 | 1 | P2 | 훅 있음 |
| sfx_charger_cancel | 예비 취소 | scenes/enemies/enemy_charger.gd :: _cancel_action | 피격으로 예비가 끊기는 짧은 취소음 | 2 | P1 | 훅 있음 |

## 5.3 등불 도깨비 (enemy_shooter)

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_lantern_hover | 부유 | scenes/enemies/enemy_shooter.gd :: _hover | 앵커 주변을 떠다니며 등불이 흔들리는 지속음 | 루프 1 | P1 | 훅 있음 |
| sfx_lantern_windup | 투척 예비 (24f) | scenes/enemies/enemy_shooter.gd :: _start_windup | 등불알을 머리 위로 들며 밝아지는 예고 | 2 | P1 | 훅 있음 |
| sfx_lantern_windup_pulse | 예비 점멸 | scenes/enemies/enemy_shooter.gd :: _pulse_windup | 난색으로 깜빡이는 등불알의 지지직 | 루프 1 | P2 | 훅 있음 |
| sfx_lantern_marker | 착탄 마커 생성 | scenes/enemies/lantern_impact.gd :: _ready | 착탄 예정 지점에 원호가 그려지는 표식음 | 2 | P1 | 훅 있음 |
| sfx_lantern_marker_fill | 마커 차오름 | scenes/enemies/lantern_impact.gd :: _process | 원호가 차오르며 조여드는 카운트다운 톤 | 루프 1 | P1 | 훅 있음 |
| sfx_lantern_throw | 투척 | scenes/enemies/enemy_shooter.gd :: _throw | 포물선으로 던져 나가는 발사음 | 3 | P1 | 훅 있음 |
| sfx_lantern_flight | 불덩이 비행 (0.90초) | scenes/weapons/projectile.gd :: _physics_process (중력 분기) | 낮은 화염 궤적음 | 루프 1 | P1 | 훅 있음 |
| sfx_lantern_ignite | 착탄 점화 | scenes/enemies/lantern_impact.gd :: on_projectile_impacted | 불이 붙는 점화 폭발음 | 3 | P1 | 훅 있음 |
| sfx_lantern_burn_loop | 화염 지대 (2.0초) | scenes/enemies/lantern_impact.gd :: _tick_burn | 타오르는 불꽃 지대 지속음 | 루프 1 | P1 | 훅 있음 |
| sfx_lantern_burn_tick | 화염 판정 (0.40초 주기) | scenes/enemies/lantern_impact.gd :: _fire_tick | 판정이 다시 켜지는 화염 틱 | 3 | P2 | 훅 있음 |
| sfx_lantern_blocked | 엄폐물에 막힘 | scenes/enemies/lantern_impact.gd :: on_projectile_impacted (반경 밖) | 불이 붙지 못하고 꺼지는 소리. 엄폐 성공 피드백 | 2 | P1 | 훅 있음 |
| sfx_lantern_absorbed | 직격으로 흡수 | scenes/enemies/lantern_impact.gd :: on_projectile_absorbed | 마커가 조용히 사라지는 흡수음 | 1 | P2 | 훅 있음 |
| sfx_lantern_evade | 도약 이탈 | scenes/enemies/enemy_shooter.gd :: _start_evade | 밀착당해 뒤로 붕 떠오르는 이탈음 | 2 | P1 | 훅 있음 |
| sfx_lantern_cancel | 투척 취소 | scenes/enemies/enemy_shooter.gd :: _cancel_throw | 예고가 취소되며 마커가 꺼지는 소거음 | 2 | P1 | 훅 있음 |
| sfx_lantern_death_wisp | 처치 시 도깨비불 점등 | 문서상 M2 과제. 코드에 없다 | 주변 도깨비불이 일제히 켜지는 점등음 | 1 | P2 | 기획만 |

## 5.4 장물아비 (enemy_fence)

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_fence_patrol | 순찰 | scenes/enemies/enemy_fence.gd :: _patrol | 보따리를 흔들며 어슬렁대는 발소리 | 3 | P1 | 훅 있음 |
| sfx_fence_approach | 접근 | scenes/enemies/enemy_fence.gd :: _approach | 잽싸게 파고드는 빠른 발소리 | 3 | P1 | 훅 있음 |
| sfx_fence_snatch_windup | 낚아채기 예비 (20f) | scripts/enemies/enemy_pattern_actor.gd :: start_pattern | 손을 앞으로 뻗는 예고 | 2 | P1 | 훅 있음 |
| sfx_fence_snatch | 낚아채기 | scripts/enemies/enemy_pattern_actor.gd :: _enter_active | 허공을 낚아채는 짧고 날카로운 손짓 | 2 | P1 | 훅 있음 |
| sfx_fence_steal | 강탈 성공 | scenes/enemies/enemy_fence.gd :: _on_snatch_landed | 엽전 꾸러미를 통째로 낚아채 가는 금속 짤랑임. 손실을 즉시 알려야 한다 | 2 | P1 | 훅 있음 |
| sfx_fence_flee | 도주 전환 | scenes/enemies/enemy_fence.gd :: _enter_flee | 보따리가 부풀며 국면이 바뀌는 전환음 | 1 | P1 | 훅 있음 |
| sfx_fence_flee_run | 도주 중 | scenes/enemies/enemy_fence.gd :: _tick_flee | 최고 속도로 달아나는 다급한 발소리 | 루프 1 | P1 | 훅 있음 |
| sfx_fence_burrow | 굴착 (40f) | scenes/enemies/enemy_fence.gd :: _enter_burrow, _tick_burrow | 마지막 처치 창을 알리는 다급한 흙 긁는 소리 | 루프 1 | P1 | 훅 있음 |
| sfx_fence_escape | 이탈 성공 | scenes/enemies/enemy_fence.gd :: _escape | 땅속으로 사라지며 엽전을 들고 튀는 소리 | 1 | P1 | 훅 있음 |
| sfx_fence_refund | 처치로 회수 | scenes/enemies/enemy_fence.gd :: _on_death_cleanup | 강탈분이 쏟아져 되돌아오는 엽전 소리 | 2 | P1 | 훅 있음 |

## 5.5 씨름꾼 (enemy_wrestler)

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_wrestler_patrol | 순찰 | scenes/enemies/enemy_wrestler.gd :: _patrol | 외다리로 껑충대며 도는 무거운 순찰음 | 3 | P1 | 훅 있음 |
| sfx_wrestler_stance | 씨름 자세 (24f) | scenes/enemies/enemy_wrestler.gd :: _enter_stance | 허리를 낮추고 자세를 잡는 굵은 기합 | 2 | P1 | 훅 있음 |
| sfx_wrestler_stance_hold | 자세 유지 | scenes/enemies/enemy_wrestler.gd :: _tick_stance | 노려보며 내는 낮은 숨소리 | 루프 1 | P2 | 훅 있음 |
| sfx_wrestler_leap_windup | 도약 돌진 예비 (20f) | scenes/enemies/enemy_wrestler.gd :: _branch_from_stance | 한 발로 힘을 모으는 예비 | 2 | P1 | 훅 있음 |
| sfx_wrestler_leap | 도약 | scenes/enemies/enemy_wrestler.gd :: _on_pattern_active | 껑충 뛰어오르며 거리를 좁히는 도약음 | 2 | P1 | 훅 있음 |
| sfx_wrestler_grab_windup | 그랩 예비 (32f, 슈퍼아머) | scenes/enemies/enemy_wrestler.gd :: _branch_from_stance | 두 팔을 벌려 붙잡으러 오는 긴 예비 기합. 도약 예비와 확실히 구분되어야 한다 | 2 | P0 | 훅 있음 |
| sfx_wrestler_grab_catch | 그랩 성사 | scenes/enemies/enemy_wrestler.gd :: _on_attack_landed | 낚아채는 확정음 | 2 | P1 | 훅 있음 |
| sfx_wrestler_throw | 배지기 | scenes/enemies/enemy_wrestler.gd :: _throw | 던져 날리는 큰 투척 기합 | 2 | P1 | 훅 있음 |
| sfx_wrestler_miss_stun | 벽 충돌 경직 (40f) | scenes/enemies/enemy_wrestler.gd :: _enter_stun | 빗나가 벽에 처박히는 충돌음. 반격 창을 알린다 | 2 | P0 | 훅 있음 |
| sfx_wrestler_stun_recover | 경직 회복 | scenes/enemies/enemy_wrestler.gd :: _tick_stun | 비틀대다 자세를 다시 잡는 회복음 | 1 | P1 | 훅 있음 |
| sfx_wrestler_leg_weakpoint | 왼다리 약점 적중 | 문서상 M2 과제. 부위 판정이 코드에 없다 | 균형이 무너지는 결정타음 | 1 | P2 | 기획만 |
| sfx_wrestler_struggle | 붙잡힘 몸싸움 | 문서상 GRAB_HOLD 구속과 연타 탈출. M2 과제 | 붙잡힌 채 몸싸움하는 지속 마찰음 | 루프 1 | P2 | 기획만 |

## 5.6 달걀도깨비 (enemy_egg)

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_egg_wander | 배회 | scenes/enemies/enemy_egg.gd :: _wander | 느릿하게 굴러다니며 자리를 옮기는 소리 | 2 | P1 | 훅 있음 |
| sfx_egg_windup | 진동 예비 (18f) | scenes/enemies/enemy_egg.gd :: _tick_windup | 제자리에서 잘게 떠는 진동 예고 | 2 | P1 | 훅 있음 |
| sfx_egg_roll_start | 구르기 개시 | scenes/enemies/enemy_egg.gd :: _enter_roll | 축선을 잡고 굴러 나가는 개시음 | 2 | P1 | 훅 있음 |
| sfx_egg_roll_loop | 구르기 중 | scenes/enemies/enemy_egg.gd :: _tick_roll | 데굴데굴 굴러오는 회전 지속음 | 루프 1 | P1 | 훅 있음 |
| sfx_egg_break_stall | 구르며 좌판 파괴 | scenes/enemies/enemy_egg.gd :: _tick_roll (try_clear_obstacle) | 뚫고 지나가는 파괴음 | 2 | P1 | 훅 있음 |
| sfx_egg_bounce | 벽 튕김 | scenes/enemies/enemy_egg.gd :: _enter_bounce | 못 넘는 벽에 튕겨 되돌아오는 탄성 충돌음 | 3 | P1 | 훅 있음 |
| sfx_egg_roll_end | 구르기 종료 | scenes/enemies/enemy_egg.gd :: _end_roll | 멈춰 서는 정지음 | 2 | P1 | 훅 있음 |
| sfx_egg_slope_accel | 경사 가속 | 문서상 미구현 | 경사에서 점점 빨라지는 가속 회전음 | 루프 1 | P2 | 기획만 |

## 5.7 짐꾼 도깨비 (enemy_porter)

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_porter_push | 밀며 전진 | scenes/enemies/enemy_porter.gd :: _push_forward | 짐을 앞세우고 느리게 미는 육중한 발걸음 | 3 | P1 | 훅 있음 |
| sfx_porter_turn | 회전 | scenes/enemies/enemy_porter.gd :: _update_facing | 굼뜨게 몸을 돌리는 회전음. 뒤로 도는 틈을 알린다 | 2 | P1 | 훅 있음 |
| sfx_porter_guard_block | 정면 가드 | scenes/enemies/enemy_porter.gd :: on_guard_blocked | 옹기 둔탁음. 정면 공격이 무효라는 즉각 피드백 | 3 | P0 | 훅 있음 |
| sfx_porter_cargo_crack | 짐 균열 | scenes/enemies/enemy_porter.gd :: on_guard_blocked (내구 감소) | 금가며 내구가 깎이는 균열음. 진행도를 소리로 알린다 | 3 (단계별) | P1 | 훅 있음 |
| sfx_porter_cargo_break | 짐 파괴 | scenes/enemies/enemy_porter.gd :: _break_cargo | 통째로 깨지고 화물이 쏟아지는 파괴음. 가드가 영구히 사라지는 순간 | 2 | P1 | 훅 있음 |
| sfx_porter_shove | 몸통 밀치기 | scenes/enemies/enemy_porter.gd :: _on_contact_landed | 몸으로 밀어붙이는 충격음 | 2 | P1 | 훅 있음 |
| sfx_porter_swing_windup | 짐 휘두르기 예비 (18f) | scripts/enemies/enemy_pattern_actor.gd :: start_pattern | 짐을 뒤로 젖혀 크게 흔들 준비 | 2 | P1 | 훅 있음 |
| sfx_porter_swing | 짐 휘두르기 | scripts/enemies/enemy_pattern_actor.gd :: _enter_active | 무거운 짐이 호를 그리며 날아오는 파공음 | 2 | P1 | 훅 있음 |
| sfx_porter_cargo_drop | 처치 시 짐 낙하 | scenes/enemies/enemy_porter.gd :: _on_death_cleanup | 짐이 떨어져 화물이 흩어지는 소리 | 2 | P1 | 훅 있음 |

---

# 6. 보스

## 6.1 문얼굴 (dokkaebi_muneolgul) 도입

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_muneolgul_speech | 개전 전 대사 | scenes/bosses/dokkaebi_muneolgul.gd :: _tick_intro | "생자가 지나갈 길은 없다"를 뱉는 돌 울림 목소리. 성우 대신 질감으로 처리 가능 | 1 | P1 | 훅 있음 |
| sfx_muneolgul_eyes_open | 눈 뜨기 | scenes/bosses/dokkaebi_muneolgul.gd :: _gaze_at_player | 두 얼굴이 함께 눈을 뜨는 석재 마찰 응시음 | 1 | P1 | 훅 있음 |
| sfx_muneolgul_awaken | 개전 | scenes/bosses/dokkaebi_muneolgul.gd :: start_encounter | 대문이 깨어나 개전을 선언하는 저역 굉음. 화면 흔들림 3.0/0.4와 동기 | 1 | P0 | 훅 있음 |
| sfx_muneolgul_hit | 피격 | scenes/bosses/dokkaebi_muneolgul.gd :: _on_hit_received | 석재 대문을 때리는 둔중한 피격음. 경직이 없어 무게로만 전달해야 한다 | 4 | P0 | 훅 있음 |
| sfx_muneolgul_face_switch | 주도 얼굴 전환 | scenes/bosses/dokkaebi_muneolgul.gd :: _apply_leader | 다음 패턴을 예고하며 한쪽 눈만 켜지는 전환 신호. 패턴 읽기의 핵심 단서 | 2 (좌우) | P0 | 훅 있음 |
| sfx_muneolgul_face_flash | 전조 점멸 | scenes/bosses/dokkaebi_muneolgul.gd :: _flash_face | 눈이 깜빡이는 고조 펄스 | 2 | P1 | 훅 있음 |

## 6.2 문얼굴 지진 패턴

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_muneolgul_quake_windup | 지진 전조 (0.5초) | scenes/bosses/dokkaebi_muneolgul.gd :: _start_quake | 좌 얼굴이 눈뜨고 땅이 웅웅대는 전조 | 1 | P1 | 훅 있음 |
| sfx_muneolgul_quake_hop | 대문 들썩임 | scenes/bosses/dokkaebi_muneolgul.gd :: _hop_gate | 광장을 흔드는 충격. 화면 흔들림 4.0/0.5 | 2 | P1 | 훅 있음 |
| sfx_muneolgul_rock_spawn | 낙석 생성 | scenes/bosses/dokkaebi_muneolgul.gd :: _spawn_rock | 화면 위에서 기와 조각이 떨어져 나오는 소리 | 3 | P1 | 훅 있음 |
| sfx_muneolgul_rock_fall | 낙석 낙하 (약 1초) | scenes/bosses/muneolgul_debris.gd :: _physics_process | 낙하 휘파람. 위치로 착탄점을 알린다 | 3 | P1 | 훅 있음 |
| sfx_muneolgul_rock_shatter | 낙석 파쇄 | scenes/bosses/muneolgul_debris.gd :: _break | 바닥에 닿아 납작하게 부서지는 파쇄음 | 4 | P1 | 훅 있음 |

## 6.3 문얼굴 넘어지기 패턴

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_muneolgul_shiver | 1단 전조 (0.7초) | scenes/bosses/dokkaebi_muneolgul.gd :: _tick_shiver | 문 전체가 부르르 떠는 전조 | 1 | P1 | 훅 있음 |
| sfx_muneolgul_lean | 2단 기울기 (1.4초) | scenes/bosses/dokkaebi_muneolgul.gd :: _start_fall_tele | 앞으로 기울며 그림자가 퍼지는 삐걱 긴장음. 회피 판단 구간 | 1 | P0 | 훅 있음 |
| sfx_muneolgul_drop | 3단 낙하 (0.5초) | scenes/bosses/dokkaebi_muneolgul.gd :: _start_fall_drop | 문짝이 통째로 쏟아지는 낙하 굉음 | 1 | P1 | 훅 있음 |
| sfx_muneolgul_slam | 바닥 충돌 | scenes/bosses/dokkaebi_muneolgul.gd :: _land_slam | 전투 최대 저역. 화면 흔들림 7.0/0.45 | 1 | P0 | 훅 있음 |
| sfx_muneolgul_slam_dust | 흙먼지 | scenes/bosses/dokkaebi_muneolgul.gd :: _flash_slam_dust | 착지 직후 퍼지는 잔향 | 2 | P1 | 훅 있음 |
| sfx_muneolgul_downed | 약점 노출 | scenes/bosses/dokkaebi_muneolgul.gd :: _land_slam (_apply_hurt_rect) | 약점 판정면이 내려와 열리는 노출 신호. 딜 창 3초의 시작 | 1 | P0 | 훅 있음 |
| sfx_muneolgul_downed_breath | 엎어진 상태 | scenes/bosses/dokkaebi_muneolgul.gd :: _tick_downed | 거칠게 숨을 몰아쉬는 지속음. 남은 시간의 단서 | 루프 1 | P1 | 훅 있음 |
| sfx_muneolgul_rise | 기립 | scenes/bosses/dokkaebi_muneolgul.gd :: _start_rise | 다시 일어서며 약점이 닫히는 석재 기립음 | 1 | P1 | 훅 있음 |

## 6.4 문얼굴 광선, 소환, 바람

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_muneolgul_beam_aim | 조준 (0.5초) | scenes/bosses/dokkaebi_muneolgul.gd :: _tick_laser | 우 얼굴 눈에 조준선이 맺히는 충전음 | 1 | P1 | 훅 있음 |
| sfx_muneolgul_beam_fire | 광선 발사 | scenes/bosses/dokkaebi_muneolgul.gd :: _fire_beam | 수평 광선이 뻗어나가는 짧고 날카로운 발사음 | 2 | P1 | 훅 있음 |
| sfx_muneolgul_beam_cancel | 조준 철회 | scenes/bosses/dokkaebi_muneolgul.gd :: _stop_beam | 접근해서 조준을 거두게 만든 소멸음. 접근 보상 피드백 | 1 | P1 | 훅 있음 |
| sfx_muneolgul_assist_beam | 보조 광선 (3페이즈) | scenes/bosses/dokkaebi_muneolgul.gd :: _tick_assist_beam | 주 패턴 위에 겹치는 얇은 발사음. 주 패턴을 가리면 안 된다 | 1 | P1 | 훅 있음 |
| sfx_muneolgul_assist_rock | 보조 낙석 (3페이즈) | scenes/bosses/dokkaebi_muneolgul.gd :: _tick_downed | 딜 창을 방해하는 짧은 낙하음 | 2 | P1 | 훅 있음 |
| sfx_muneolgul_door_open | 문짝 개방 | scenes/bosses/dokkaebi_muneolgul.gd :: _set_doors_open | 육중한 문짝이 밀려 열리는 삐걱 개방음 | 1 | P1 | 훅 있음 |
| sfx_muneolgul_summon | 잡도깨비 소환 | scenes/bosses/dokkaebi_muneolgul.gd :: _release_minion | 문틈에서 한 기씩 걸어 나오는 발소리 | 3 | P1 | 훅 있음 |
| sfx_muneolgul_door_slam | 문짝 닫힘 | scenes/bosses/dokkaebi_muneolgul.gd :: _slam_doors_shut | 코드 주석이 명시적으로 요구하는 소리다. "이 소리 없는 쾅이 소환 국면의 끝을 알린다" | 1 | P0 | 훅 있음 |
| sfx_muneolgul_wind_start | 강풍 개시 | scenes/bosses/dokkaebi_muneolgul.gd :: _start_wind_blow | 문간에서 터져 나오는 돌풍 | 1 | P1 | 훅 있음 |
| sfx_muneolgul_wind_loop | 강풍 지속 (4.5초) | scenes/bosses/dokkaebi_muneolgul.gd :: _tick_wind | 전진을 막는 지속 강풍. 조작 저항을 소리로 전달한다 | 루프 1 | P1 | 훅 있음 |
| sfx_muneolgul_obstacle | 궤짝 투척 (0.42초 간격) | scenes/bosses/dokkaebi_muneolgul.gd :: _spawn_obstacle | 궤짝과 항아리가 직선으로 날아오는 투척음. 3단 높이 순환이라 높이별 음정 분리 권장 | 3 (높이별) | P1 | 훅 있음 |
| sfx_muneolgul_wind_end | 강풍 해제 | scenes/bosses/dokkaebi_muneolgul.gd :: _start_wind_close | 바람이 잦아들고 문이 닫히는 해제음 | 1 | P1 | 훅 있음 |
| sfx_muneolgul_death | 처치 | scenes/bosses/dokkaebi_muneolgul.gd :: _on_died | 대문이 무너져 내리는 대규모 붕괴음 | 1 | P0 | 훅 있음 |

## 6.5 방망이 (dokkaebi_bangmangi)

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_bangmangi_hover | 부유 드리프트 | scenes/bosses/dokkaebi_bangmangi.gd :: _tick_phase1 | 좌우로 흔들리는 나무 방망이 회전음 | 루프 1 | P1 | 훅 있음 |
| sfx_bangmangi_cast_fire | 도깨비불 소환 | scenes/bosses/dokkaebi_bangmangi.gd :: _cast_fire | 허공을 두드려 불을 뽑아내는 요술 발동음. 간격 1.6초(p1) / 1.1초(p2) | 3 | P1 | 훅 있음 |
| sfx_bangmangi_cast_treasure | 재물 소환 | scenes/bosses/dokkaebi_bangmangi.gd :: _cast_treasure | 금은보화를 머리 위에 소환하는 짤랑임 | 2 | P1 | 훅 있음 |
| sfx_bangmangi_treasure_fall | 재물 낙하 | scenes/bosses/dokkaebi_bangmangi.gd :: _cast_treasure (launch DOWN) | 수직 낙하해 내리꽂히는 무거운 낙하음 | 3 | P1 | 훅 있음 |
| sfx_bangmangi_smash_windup | 난타 예비 (0.35초) | scenes/bosses/dokkaebi_bangmangi.gd :: _start_smash | 방망이를 치켜드는 예비 파공 | 2 | P1 | 훅 있음 |
| sfx_bangmangi_smash | 난타 | scenes/bosses/dokkaebi_bangmangi.gd :: _tick_smash | 근접 난타가 내리꽂히는 타격음 | 3 | P1 | 훅 있음 |
| sfx_bangmangi_cancel | 난타 취소 | scenes/bosses/dokkaebi_bangmangi.gd :: _cancel_action | 피격으로 끊기는 취소음 | 2 | P1 | 훅 있음 |
| sfx_bangmangi_death | 처치 | scripts/enemies/boss_base.gd :: _on_died | 요술이 풀려 방망이가 나뒹구는 처치음 | 1 | P1 | 훅 있음 |
| sfx_bangmangi_treasure_shadow | 낙하 예고 그림자 | 문서상 "그림자 표시 후 낙하". 코드에 예고 그림자가 없다 | 낙하 지점을 알리는 예고 표식음 | 1 | P2 | 기획만 |
| sfx_bangmangi_transform | 사물 변형 | 문서상 좌판과 항아리를 공격체로 변형. 미구현 | 요술로 무기가 되는 변형음 | 2 | P2 | 기획만 |

## 6.6 보스 공통

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_boss_phase_lock | 페이즈 전환 무적 | scripts/enemies/boss_base.gd :: _apply_phase (set_invulnerable) | 전환 연출 동안 무적이 걸리고 풀리는 결계음 | 2 (진입, 해제) | P1 | 훅 있음 |
| sfx_boss_reward | 보상 지급 | scripts/enemies/boss_base.gd :: _grant_reward | 권능, 진품 유물, 엽전이 지급되는 보상 확정음 | 1 | P1 | 훅 있음 |

## 6.7 중간보스와 히든 보스 (전부 미구현)

`scenes/midbosses/` 디렉터리 자체가 없다. 사운드보다 코드가 먼저다. 목록만 남긴다.

| 대상 | 사운드가 설계 조건인 지점 | 우선 | 상태 |
|---|---|---|---|
| 어둑시니 | 등불을 끄고 어둠 속에서 커진다. 명암과 크기 변화에 연동되는 음향 레이어가 필요한 유일한 개체 | P2 | 기획만 |
| 씨름 장사 황소 | 라운드제 장외 승부. 라운드 종료 신호가 필요 | P2 | 기획만 |
| 왕초 장물아비 | 훔칠수록 강해진다. 단계별 강화 상승음 | P2 | 기획만 |
| 수레 멧돼지 | 수레 돌진과 파괴, 옹기 폭탄 | P2 | 기획만 |
| 감투 노인 | 문서가 명시적으로 "소리 단서로 예측"을 요구한다. 은신 위치를 알리는 청각 신호가 설계 조건이다 | P2 | 기획만 |
| 도깨비왕 (히든) | "1막 내내 기울던 달이 조우 시 그의 눈 위치로 들어간다". 전용 음악 처리 지점 | P2 | 기획만 |

---

# 7. 미니게임

세 씬 모두 자식 노드 없이 `_draw()`에서 전부 그린다. 사운드 훅도 노드 시그널이 아니라 상태 전이 함수에 직접 넣어야 한다.

## 7.1 씨름

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_ssireum_offer_move | 선택지 이동 | scenes/minigame/ssireum_minigame.gd :: _input_offer | 목록을 훑는 마른 딸깍 | 2 | P1 | 훅 있음 |
| sfx_ssireum_offer_confirm | 참가 확정 | 동상 (jump 또는 ui_accept) | 판에 들어서겠다는 결정을 못박는 둔탁한 확정음 | 1 | P1 | 훅 있음 |
| sfx_ssireum_satba | 샅바 잡기 | scenes/minigame/ssireum_minigame.gd :: _gripping | 삼베 샅바를 감아쥐고 당기는 거친 마찰음 | 3 | P1 | 훅 있음 |
| sfx_ssireum_count | 구호 (3, 2, 1) | scenes/minigame/ssireum_minigame.gd :: _draw_count (0.6초 간격) | 마디마다 떨어지는 짧고 마른 북 한 대 | 3 (음정 상승) | P0 | 훅 있음 |
| sfx_ssireum_go | 시작 | 동상 ("시작" 마디) | 꽹과리 한 방. 연타 개시 신호 | 1 | P0 | 훅 있음 |
| sfx_ssireum_mash_hit | 연타 성공 | scenes/minigame/ssireum_minigame.gd :: _input (press true) | 몸을 밀어내는 짧고 단단한 타격음. 게임에서 가장 빠르게 반복되는 큐 | 4 | P0 | 훅 있음 |
| sfx_ssireum_mash_miss | 연타 실패 | 동상 (press false) | 헛손질로 힘이 새는 둔한 미끄럼음 | 3 | P1 | 훅 있음 |
| sfx_ssireum_prompt_next | 방향 전환 | scripts/systems/ssireum_duel.gd :: roll_prompt | 방향 하나를 넘겼다고 알리는 맑은 딸깍 | 2 | P1 | 훅 있음 |
| sfx_ssireum_strain | 힘겨루기 지속 | scenes/minigame/ssireum_minigame.gd :: _draw_actors (Phase.DUEL) | 샅바를 잡고 버티는 두 사람의 숨과 옷깃 스침 | 루프 1 | P1 | 훅 있음 |
| sfx_ssireum_time_warning | 시간 경고 (8초) | scenes/minigame/ssireum_minigame.gd :: _draw_gauge (WARN_TIME) | 남은 시간이 드러날 때 한 번 울리는 낮은 종 | 1 | P1 | 훅 있음 |
| sfx_ssireum_throw | 메다꽂기 | scenes/minigame/ssireum_minigame.gd :: _finish_duel | 몸이 모래판에 꽂히는 묵직한 낙하음 | 2 | P1 | 훅 있음 |
| sfx_ssireum_win | 승리 | 동상 (player_won) | 짧은 승리 가락 | 1 | P1 | 훅 있음 |
| sfx_ssireum_lose | 패배 | 동상 | 판을 내주고 물러나는 가라앉는 단음 | 1 | P1 | 훅 있음 |
| sfx_ssireum_skip | 지나가기 | scenes/minigame/ssireum_minigame.gd :: _skip | 판을 비켜 지나가는 발소리와 잦아드는 웅성거림 | 1 | P2 | 훅 있음 |
| sfx_crowd_ssireum_loop | 관중 (17명) | scenes/minigame/ssireum_minigame.gd :: _draw_crowd | 귀신과 도깨비 관중의 응원 웅성거림 | 루프 1 | P1 | 훅 있음 |
| sfx_crowd_ssireum_cheer | 관중 환호 | scenes/minigame/ssireum_minigame.gd :: _finish_duel (승리) | 터지는 환호와 박수 | 2 | P1 | 훅 있음 |
| sfx_crowd_ssireum_groan | 관중 탄식 | 동상 (패배) | 낮은 탄식 | 2 | P1 | 훅 있음 |
| sfx_ssireum_true_form | 정체 폭로 | scenes/minigame/ssireum_minigame.gd :: _finish_duel (연출 없음) | 도깨비가 헌 빗자루나 절굿공이로 되돌아가는 마른 나무 소리 | 2 | P2 | 기획만 |

## 7.2 노름판

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_gamble_offer_move | 선택지 이동 | scenes/minigame/gamble_minigame.gd :: _input_offer | 마른 딸깍 | 2 | P1 | 훅 있음 |
| sfx_gamble_bet_kind | 베팅 종류 선택 (소, 대, 쌍) | scenes/minigame/gamble_minigame.gd :: _input_bet_kind | 베팅 칸을 옮겨 짚는 나무 두드림 | 2 | P1 | 훅 있음 |
| sfx_gamble_bet_step | 판돈 증감 | scenes/minigame/gamble_minigame.gd :: _input_bet_amount | 엽전 한 닢을 더 얹거나 빼는 금속 부딪힘 | 3 | P1 | 훅 있음 |
| sfx_gamble_pot_stack | 판돈 쌓임 (최대 12닢) | scenes/minigame/gamble_minigame.gd :: _draw_pot | 엽전 무더기가 멍석 위에 쌓이는 소리 | 3 | P1 | 훅 있음 |
| sfx_gamble_bet_commit | 판돈 확정 | scenes/minigame/gamble_minigame.gd :: _play_round | 판돈을 밀어 놓는 결단의 묵직한 한 번 | 1 | P1 | 훅 있음 |
| sfx_gamble_deal | 패 돌리기 (4장, 0.14초 간격) | scenes/minigame/gamble_minigame.gd :: _deal_ratio | 종이패가 멍석 위를 미끄러지는 사르륵 | 4 | P1 | 훅 있음 |
| sfx_gamble_flip | 패 뒤집기 | scenes/minigame/gamble_minigame.gd :: _flip_squash | 손끝에서 튕기는 짧은 탁 | 4 | P1 | 훅 있음 |
| sfx_gamble_tile | 골패 부딪힘 | scenes/minigame/gamble_minigame.gd :: _draw_tile | 골패가 서로 부딪히는 단단한 뼈 소리 | 4 | P1 | 훅 있음 |
| sfx_gamble_dice_shake | 주사위 흔들기 (0.45초) | scenes/minigame/gamble_minigame.gd :: _die_state | 통 안에서 요란하게 구르는 반복음 | 루프 1 | P1 | 훅 있음 |
| sfx_gamble_dice_roll | 주사위 굴리기 (3회 튐) | 동상 (SHAKE_END ~ ROLL_END) | 멍석으로 쏟아져 세 번 튀며 구르는 소리 | 3 | P1 | 훅 있음 |
| sfx_gamble_dice_settle | 눈 확정 | 동상 (ROLL_END 이후) | 멎는 마지막 한 번의 톡. 결과 공개 직전의 정적을 만든다 | 2 | P1 | 훅 있음 |
| sfx_gamble_win | 승리 | scenes/minigame/gamble_minigame.gd :: _show_verdict (PLAYER) | 튀어오르는 밝은 금속성 스팅어. 등불 호박색에 대응 | 1 | P1 | 훅 있음 |
| sfx_gamble_lose | 패배 | 동상 (DEALER) | 가라앉는 어두운 남색 단음 | 1 | P1 | 훅 있음 |
| sfx_gamble_push | 무승부 | 동상 (PUSH) | 흐지부지 풀리는 중립 신호 | 1 | P1 | 훅 있음 |
| sfx_gamble_coins_fly | 엽전 이동 (9닢, 0.75초) | scenes/minigame/gamble_minigame.gd :: _spawn_coins | 포물선을 그리며 이긴 쪽으로 쏟아지는 소리 | 2 | P1 | 훅 있음 |
| sfx_gamble_leave | 판 거절 | scenes/minigame/gamble_minigame.gd :: _finish (_played false) | 자리를 뜨는 옷자락과 멀어지는 웅성거림 | 1 | P2 | 훅 있음 |
| sfx_crowd_gamble_loop | 구경꾼 (6명) | scenes/minigame/gamble_minigame.gd :: _draw_crowd | 낮고 끈적한 잡담 | 루프 1 | P1 | 훅 있음 |
| sfx_crowd_gamble_gasp | 구경꾼 숨 들이킴 | scenes/minigame/gamble_minigame.gd :: _show_verdict | 패가 열리는 순간 일제히 들이켜는 숨 | 2 | P1 | 훅 있음 |
| sfx_crowd_gamble_jeer | 구경꾼 야유 | 동상 (DEALER) | 잃은 쪽을 향한 야유와 낄낄거림 | 2 | P1 | 훅 있음 |
| sfx_dealer_gloat | 노름꾼 자랑 | scenes/minigame/gamble_minigame.gd :: _dealer_texture (DEALER) | 폴짝거리며 뽐내는 도깨비 웃음 | 2 | P1 | 훅 있음 |
| sfx_dealer_tumble | 노름꾼 나뒹굴기 | 동상 (PLAYER) | 억울한 신음 | 2 | P1 | 훅 있음 |

## 7.3 장물아비 추격

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_chase_steal | 강탈 개시 | scenes/minigame/chase_minigame.gd :: _begin_chase | 소매를 훑고 달아나는 날카로운 낚아챔 | 1 | P1 | 훅 있음 |
| sfx_chase_taunt | 조롱 (소지금 부족) | scenes/minigame/chase_minigame.gd :: _begin_taunt | 훔칠 게 없다며 코웃음 치고 물러나는 김빠진 단음 | 1 | P2 | 훅 있음 |
| sfx_chase_footsteps | 달리기 | scenes/minigame/chase_minigame.gd :: Phase.RUN | 흙바닥을 차는 빠른 발소리 루프. 속도에 따라 피치 조정 | 루프 1 | P1 | 훅 있음 |
| sfx_chase_lane_shift | 레인 이동 | scenes/minigame/chase_minigame.gd :: _follow_lane | 몸을 기울여 꺾는 짧은 스텝음 | 3 | P1 | 훅 있음 |
| sfx_chase_obstacle_hit | 장애물 충돌 | scenes/minigame/chase_minigame.gd :: _watch_events | 궤짝과 항아리에 부딪혀 깨지고 나뒹구는 충돌음 | 4 | P1 | 훅 있음 |
| sfx_chase_lamp_out | 등불 소등 | scenes/minigame/chase_minigame.gd :: _draw_hit_lamps | 등불 하나가 꺼지는 짧고 서늘한 소등음. 남은 기회를 알린다 | 3 (단계별) | P1 | 훅 있음 |
| sfx_chase_thief_evade | 장물아비 회피 | scripts/systems/chase_run.gd :: _drift_lane | 옆으로 빠지며 내지르는 짧은 낄낄거림 | 3 | P1 | 훅 있음 |
| sfx_chase_gap_reset | 놓침 | scripts/systems/chase_run.gd :: _advance_target | 손끝에서 놓쳐 다시 멀어지는 실망의 스침 | 2 | P1 | 훅 있음 |
| sfx_chase_catch | 포착 | scenes/minigame/chase_minigame.gd :: _watch_events (caught) | 덜미를 낚아채는 둔탁한 포착음 | 3 | P1 | 훅 있음 |
| sfx_chase_coin_scatter | 엽전 회수 (7닢) | scenes/minigame/chase_minigame.gd :: _spawn_coins | 보따리가 터지며 엽전이 흩어지는 소리 | 2 | P1 | 훅 있음 |
| sfx_chase_win | 전원 회수 | scenes/minigame/chase_minigame.gd :: _finish_run (all_caught) | 짧은 승리 스팅어 | 1 | P1 | 훅 있음 |
| sfx_chase_fail | 추격 포기 | 동상 (failed) | 숨을 몰아쉬며 멈춰 서는 소진음 | 1 | P1 | 훅 있음 |
| sfx_chase_near_miss | 아슬아슬한 통과 | 근접 통과 판정이 없다 (충돌만 본다) | 스쳐 지나갈 때의 바람 소리 | 3 | P2 | 코드 선행 |

---

# 8. 신당, 권능, 이벤트

## 8.1 신당

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_shrine_enter | 신당 진입 | scenes/levels/room_shrine.gd :: _on_shrine_entered | 짧고 맑은 방울 한 번. 신성 신호 음색의 기준점 | 1 | P0 | 훅 있음 |
| sfx_shrine_offer_open | 3택 제시 | scenes/levels/room_shrine.gd :: _open_offer_panel | 낮게 울리는 공명. 몸주 신당은 더 격식 있게, 권능 신당은 소박하게 | 2 (신당별) | P1 | 훅 있음 |
| sfx_shrine_reroll | 재추첨 (무당 방울 소모) | scenes/levels/room_shrine.gd :: _try_reroll | 방울을 흔들어 점괘를 다시 뽑는 금속 방울 | 2 | P1 | 훅 있음 |
| sfx_shrine_reroll_denied | 재추첨 불가 | 동상 (실패 반환) | 다시 굴릴 수 없다고 막는 무딘 거절음 | 1 | P1 | 훅 있음 |
| sfx_shrine_light_response | 신의 응답 | scenes/levels/room_shrine.gd :: _pulse_response_lights | 촛불과 달빛의 광량이 튀어오르는 순간의 숨결 | 1 | P1 | 훅 있음 |
| sfx_shrine_capacity_full | 권능 칸 초과 | scenes/levels/room_shrine.gd :: _open_capacity_menu | 더 담을 수 없다고 알리는 둔한 경고음 | 1 | P1 | 훅 있음 |
| sfx_shrine_discard | 권능 폐기 | scenes/levels/room_shrine.gd :: _resolve_capacity_discard | 가진 권능을 떼어내 버리는 파쇄음 | 1 | P1 | 훅 있음 |
| sfx_shrine_decline | 수령 거절 | scenes/levels/room_shrine.gd :: _resolve_capacity | 받기를 포기하고 물러서는 가라앉는 단음 | 1 | P2 | 훅 있음 |
| sfx_shrine_revisit_empty | 이미 다녀간 신당 | scenes/levels/room_shrine.gd :: _on_shrine_entered (is_empty_room) | 비어 버린 신당의 텅 빈 잔향 | 1 | P2 | 훅 있음 |

## 8.2 권능 획득과 융합

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_boon_grant_mongju | 몸주 결정 | autoload/run_state.gd :: commit_mongju | 몸주가 내려앉는 길고 무거운 강신음. 런에서 한 번뿐인 계열 결정 | 1 | P0 | 훅 있음 |
| sfx_boon_grant | 권능 획득 | autoload/run_state.gd :: commit_boon | 권능이 몸에 스미는 신내림. 등급이 높을수록 화려하게 | 3 (등급별) | P0 | 훅 있음 |
| sfx_fusion_open | 융합 메뉴 열기 | scenes/levels/room_shrine.gd :: _try_open_fusion_menu | 두 권능을 맞대어 보는 낮은 마찰 공명 | 1 | P1 | 훅 있음 |
| sfx_fusion_preview | 재료 대조 | scripts/systems/boon_fusion.gd :: preview | 재료를 맞대볼 때 나는 옅은 UI 틱 | 2 | P2 | 훅 있음 |
| sfx_fusion_roll | 성패 판정 직전 | scenes/levels/room_shrine.gd :: _resolve_fusion_confirm | 감아 올라가는 긴장음 | 1 | P1 | 훅 있음 |
| sfx_fusion_success | 융합 성공 | scripts/systems/boon_fusion.gd :: resolve (great false) | 두 힘이 맞물리는 맑은 성공음 | 1 | P1 | 훅 있음 |
| sfx_fusion_great | 융합 대성공 (겹내림) | scripts/systems/boon_fusion.gd :: _apply_great_bonus | 런에서 가장 화려한 보상음. 등급 상승까지 얹힌다 | 1 | P1 | 훅 있음 |
| sfx_fusion_fail | 융합 실패 | scenes/levels/room_shrine.gd :: _fusion_result_message (ok false) | 힘이 흩어지며 꺼지는 짧은 실패음 | 1 | P1 | 훅 있음 |
| sfx_fusion_denied | 융합 거부 | scripts/systems/boon_fusion.gd :: check (실패 반환) | 짧고 단호한 거절. 사유별로 나눌 필요는 없다 | 1 | P1 | 훅 있음 |

## 8.3 권능 발동 (계열별)

| 큐 ID | 권능 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_boon_cast | 액티브 발동 (공통) | autoload/boon_runtime.gd :: try_cast_active | 신이 내리는 순간의 방울과 숨. 개별 권능음 아래 깔리는 공통 레이어 | 1 | P0 | 훅 있음 |
| sfx_boon_cast_fail | 발동 실패 (쿨다운) | 동상 (_cooldown_left > 0) | 아직 응답이 없는 먹먹한 불발 | 1 | P1 | 훅 있음 |
| sfx_boon_ready | 쿨다운 회복 | autoload/boon_runtime.gd :: _emit_active_state | 다시 부를 수 있게 된 맑은 신호 | 1 | P1 | 훅 있음 |
| sfx_boon_sanppyeo | 산의 뼈 (산신) | autoload/boon_runtime.gd :: _cast_san_ppyeo | 제자리에 굳는 석화. 시작, 버티는 저역 루프, 풀리는 해제 3단 | 시작 1, 루프 1, 해제 1 | P1 | 훅 있음 |
| sfx_boon_beom_ippal | 범의 이빨 (산신) | autoload/boon_runtime.gd :: _cast_beom_ippal | 기력을 태워 얻는 짐승의 포효. 지속 동안 검에 실린 낮은 으르렁 루프 | 2 + 루프 1 | P1 | 훅 있음 |
| sfx_boon_bawi_arm | 바위 치기 장전 (산신) | autoload/boon_runtime.gd :: _cast_bawi_chigi | 다음 한 방에 기운이 실리는 응축 | 1 | P1 | 훅 있음 |
| sfx_boon_bawi_impact | 바위 치기 타격 | autoload/boon_runtime.gd :: _apply_rock_strike | 육중한 타격과 밀어냄 | 2 | P1 | 훅 있음 |
| sfx_boon_bawi_wallslam | 바위 치기 벽 충돌 | 동상 (_wall_within 통과) | 벽에 처박히는 최대 보상 구간. 가장 크고 파괴적인 충돌 | 2 | P1 | 훅 있음 |
| sfx_boon_agungi | 아궁이 (조왕) | autoload/boon_runtime.gd :: _cast_agungi | 발밑에 불자리를 지피는 점화와 장작 | 1 | P1 | 훅 있음 |
| sfx_hearth_loop | 불자리 지속 | scripts/systems/hearth_zone.gd :: _process | 타는 화염 루프와 잦아드는 소멸 | 루프 1 + 소멸 1 | P1 | 훅 있음 |
| sfx_poker_throw | 부지깽이 투척 (조왕) | autoload/boon_runtime.gd :: _throw_poker_flame | 불꽃을 퍼올려 던지는 휙. 조작과 무관하게 주기로 반복되므로 변형 필수 | 3 | P1 | 훅 있음 |
| sfx_poker_hit | 부지깽이 착화 | scripts/systems/poker_flame.gd :: _scorch | 불꽃이 적에 달라붙는 착화 | 2 | P1 | 훅 있음 |
| sfx_boon_bulti | 불티 (조왕) | autoload/boon_runtime.gd :: notify_ranged_hit | 재장전 뒤 첫 명중에만 얹히는 특별한 불꽃. 조건 달성을 알리는 보상감 | 1 | P1 | 훅 있음 |

## 8.4 이벤트

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_event_choice_show | 선택지 제시 | scenes/ui/shrine_panel.gd :: open | 종이 펴짐 | 1 | P1 | 훅 있음 |
| sfx_event_choice_blocked | 선택 불가 | scenes/ui/shrine_panel.gd :: _confirm (_disabled 조기 반환) | 고를 수 없다고 막아서는 짧은 거절음. 현재 무반응이라 사용자 혼란 지점 | 1 | P1 | 훅 있음 |
| sfx_event_reward_relic | 유물 획득 | scenes/levels/run_stage.gd :: _grant_result_relic | 떨이 유물을 손에 넣는 낡고 둔탁한 획득음 | 2 | P1 | 훅 있음 |
| sfx_event_penalty | 결과 피해 | scenes/levels/run_stage.gd :: _on_minigame_finished | 결과로 체력을 잃을 때의 짧은 피격음 | 1 | P1 | 훅 있음 |
| sfx_event_gut_gong | 도깨비굿 소리 기믹 (N6) | 문서상 M3. 이벤트 자체가 미구현 | 솥뚜껑과 양푼을 치면 도깨비가 물러난다. 사운드가 게임플레이 그 자체인 유일한 콘텐츠 | 3 | P2 | 기획만 |

---

# 9. UI와 시스템

## 9.1 환경 인터랙션

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_gwimun_appear | 귀문 출현 | scenes/levels/exit_door.gd :: appear | 도깨비스러운 뿅 하는 팝과 청록 섬광. 방 클리어의 보상 신호 | 1 | P0 | 훅 있음 |
| sfx_gwimun_enter | 귀문 통과 | scenes/levels/exit_door.gd :: _on_body_entered | 문지방을 넘는 순간의 흡입감 | 1 | P0 | 훅 있음 |
| sfx_lantern_switch | 등불 스위치 점등 | scenes/levels/lantern_switch.gd :: _on_triggered | 불이 붙는 확 하는 점화음 | 2 | P1 | 훅 있음 |
| sfx_wisp_light | 도깨비불 발판 점등 | scenes/levels/wisp_platform.gd :: light | 청록 점등음. 색 채널 규약상 청록 전용 음색 | 2 | P1 | 훅 있음 |
| sfx_wisp_blink | 발판 소멸 경고 | scenes/levels/wisp_platform.gd :: _apply_blink | 꺼지기 직전의 조급한 깜빡임 틱. 발판에서 내려오라는 신호 | 루프 1 | P1 | 훅 있음 |
| sfx_wisp_out | 발판 소등 | scenes/levels/wisp_platform.gd :: _extinguish | 훅 사라지는 소등음 | 2 | P1 | 훅 있음 |
| sfx_stall_hit | 좌판 피격 | scenes/levels/stall_cover.gd :: _on_hit_received | 나무 좌판을 때린 둔탁한 타격 | 3 | P1 | 훅 있음 |
| sfx_stall_break | 좌판 파괴 | scenes/levels/stall_cover.gd :: _on_broken | 주저앉으며 판자와 물건이 쏟아짐 | 3 | P1 | 훅 있음 |

## 9.2 허브 인터랙션

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| sfx_npc_startled | NPC 놀람 | scripts/npc/npc_actor.gd :: react_startled_silent | 놀라 튀어오르는 짧은 헛숨. 해학 표현 지점 | 3 | P1 | 훅 있음 |
| sfx_hub_gate_locked | 상행문 잠김 | scenes/hub/hub.gd :: _try_depart (can_depart 거짓) | 잠긴 문을 미는 둔한 저항음 | 1 | P1 | 훅 있음 |
| sfx_hub_grant | 물건 수령 | scenes/hub/hub.gd :: _grant_sword, _grant_map, _unlock_gun | 건네받는 확정감 있는 짧은 강조 | 2 | P1 | 훅 있음 |
| sfx_hub_weapon_swap | 시작 무기 교체 | scenes/hub/hub.gd :: _swap_start_weapon | 무기를 바꿔 쥐는 금속 마찰 | 1 | P1 | 훅 있음 |

## 9.3 UI 조작

| 큐 ID | 동작 | 트리거 위치 | 성격 | 변형 | 우선 | 상태 |
|---|---|---|---|---|---|---|
| ui_cursor_move | 커서 이동 | scenes/ui/shrine_panel.gd :: _move, scenes/ui/node_map.gd :: _move_selection | 붓끝이 종이를 스치는 짧은 마찰. UI에서 가장 자주 들린다 | 2 | P0 | 훅 있음 |
| ui_confirm | 확정 | scenes/ui/shrine_panel.gd :: _confirm, node_map.gd :: _confirm, main_menu 버튼 | 도장을 찍는 단단한 확정음. 관료 톤과 직결되는 소리 | 1 | P0 | 훅 있음 |
| ui_cancel | 취소 | scenes/ui/shrine_panel.gd :: _cancel, settings_menu.gd :: _on_back_pressed | 확정음을 뒤집은 낮은 취소음 | 1 | P0 | 훅 있음 |
| ui_disabled | 선택 불가 | scenes/ui/shrine_panel.gd :: _confirm (조기 반환) | 둔탁한 막힘 | 1 | P1 | 코드 선행 |
| ui_pause_open | 일시정지 열기 | scenes/ui/pause_menu.gd :: _open | 시간이 멎는 짧은 흡입 | 1 | P0 | 훅 있음 |
| ui_pause_close | 일시정지 닫기 | scenes/ui/pause_menu.gd :: _close | 시간이 다시 흐르는 해제음 | 1 | P0 | 훅 있음 |
| ui_status_open | 상태창 열기 | scenes/ui/status_panel.gd :: _open | 두루마리를 펴는 종이 소리 | 1 | P1 | 훅 있음 |
| ui_status_close | 상태창 닫기 | scenes/ui/status_panel.gd :: _close | 두루마리를 마는 소리 | 1 | P1 | 훅 있음 |
| ui_map_unfold | 지도 펼치기 (0.5초) | scenes/ui/node_map.gd :: open | 접힌 지도를 양손으로 펼치는 종이 소리 | 1 | P0 | 훅 있음 |
| ui_map_fold | 지도 접기 | scenes/ui/node_map.gd :: _confirm, close | 접어 넣는 마무리 | 1 | P0 | 훅 있음 |
| ui_map_node_pick | 지도 노드 선택 | scenes/ui/node_map.gd :: _click_at | 방표를 짚는 짧은 먹점 | 2 | P1 | 훅 있음 |
| ui_dialogue_open | 대화창 열기 | scenes/ui/dialogue_box.gd :: open | 종이 펼침 | 1 | P0 | 훅 있음 |
| ui_dialogue_type | 글자 출력 | scenes/ui/dialogue_box.gd :: _process (REVEAL_SPEED, 45자/초) | 글자마다 찍히는 아주 짧은 틱. 볼륨을 낮게, 피치를 랜덤하게 | 3 | P0 | 훅 있음 |
| ui_dialogue_advance | 다음 줄 | scenes/ui/dialogue_box.gd :: _advance | 낮은 페이지 넘김 | 1 | P0 | 훅 있음 |
| ui_dialogue_close | 대화창 닫기 | scenes/ui/dialogue_box.gd :: _close | 여운 짧은 마감 | 1 | P1 | 훅 있음 |
| ui_dialogue_effect | 강조 줄 | scenes/ui/dialogue_box.gd :: _fire_effect_of_current | 등불색으로 강조되는 줄에 얹는 강조 배음 | 1 | P1 | 훅 있음 |
| ui_popup_show | 결과 팝업 표시 | scenes/ui/event_result_popup.gd :: show_result | 결과 팻말이 내려앉는 소리 | 1 | P1 | 훅 있음 |
| ui_popup_close | 결과 팝업 소멸 | scenes/ui/event_result_popup.gd :: _close | 페이드에 맞춘 조용한 소멸 | 1 | P2 | 훅 있음 |
| ui_toast | 한 줄 알림 | scenes/hub/hub.gd :: _show_message | 가벼운 틱 | 1 | P1 | 훅 있음 |
| ui_scene_fade | 씬 전환 암전 | autoload/scene_router.gd :: _fade_to (fade_time 0.35) | 저역 스윕. 모든 씬 전환 공통이므로 BGM 크로스페이드와 동기시킨다 | 1 | P0 | 훅 있음 |
| ui_settings_open | 설정 열기 | scenes/ui/settings_menu.gd :: show_panel | 하위 패널이 겹쳐 뜨는 짧은 슬라이드 | 1 | P1 | 훅 있음 |
| ui_confirm_dialog | 되돌릴 수 없는 확인 | scenes/ui/main_menu.gd :: _on_restart_pressed | 무거운 경고 | 1 | P1 | 훅 있음 |
| ui_quit | 게임 종료 | autoload/scene_router.gd :: quit_game | 마지막 한 음 | 1 | P2 | 훅 있음 |

---

# 부록 A. 코드 선행이 필요한 항목

사운드 클립을 만들어도 붙일 자리가 없어 코드 작업이 먼저다.

| 항목 | 사유 | 필요한 코드 작업 |
|---|---|---|
| 플레이어 발소리 | run 클립 선택만 있고 접지 프레임 훅이 없다 | 애니메이션 프레임 신호 또는 이동 거리 누적 방식 |
| 강한 착지 구분 | 낙하 속도 분기가 없다 | `_tick_body_stretch`에서 velocity.y로 분기 |
| 벽 붙기 개시 | `_wall_sliding`의 false to true 전이 판별이 없다 | 전이 판별 추가 |
| 빈 격발 | `try_fire`가 실패 사유 없이 false만 반환한다 | 실패 사유 시그널 신설 |
| 저체력 경고 | 임계값 판정이 없다 | HUD 또는 player에서 비율 임계 판정 |
| 회복음 | `health.heal()`에 호출자가 코드베이스 전체에 없다 | 회복 소스 연결이 먼저 |
| 적 인지 (ALERT) | 문서상 인지 지연 0.2~0.4초가 있으나 코드는 거리 비교만 한다 | ALERT 상태 신설 |
| 적 등장 (SPAWN) | 문서상 등장 연출과 짧은 무적이 있으나 코드에 없다 | SPAWN 상태 신설 |
| 패링 전체 | 시스템 자체가 미구현. 설계는 docs/systems/WEAPONS.md 7장에 완비 | 패링 판정 구현 |
| 추격 아슬아슬 통과 | 근접 통과 판정이 없다 (충돌만 본다) | near miss 판정 추가 |
| 밤바람, 귀문 앰비언스 | 배경 프리셋에 대응 신호가 없다 | 프리셋 전환 시그널 노출 |

# 부록 B. 최소 재생 가능 세트 (P0, 78종)

이것만 있으면 게임이 무음으로 느껴지지 않는다. 작업 순서로 보면 1단계다.
분류별 목록은 본문 표에서 우선순위 P0으로 표기된 큐를 그대로 뽑은 것이다.

## 음악 (BGM) (6)

bgm_title, bgm_hub, bgm_act1_explore, bgm_act1_combat, bgm_shrine, bgm_boss_muneolgul_p1

## 앰비언스 (2)

amb_act1_street, amb_hub_office

## 스팅어 (7)

stg_run_start, stg_room_clear, stg_rage_warning, stg_rage_trigger, stg_boss_encounter, stg_boss_defeat, stg_run_fail

## 플레이어 (22)

sfx_player_footstep, sfx_player_jump, sfx_player_walljump, sfx_player_land, sfx_player_dash, sfx_player_dash_fail, sfx_melee_swing_1, sfx_melee_swing_2, sfx_melee_swing_3, sfx_melee_air_swing, sfx_melee_hit, sfx_melee_hit_finisher, sfx_rifle_fire, sfx_rifle_last_round, sfx_rifle_reload_start, sfx_rifle_reload_finish, sfx_bullet_impact_flesh, sfx_bullet_impact_wall, sfx_guard_blocked, sfx_player_hurt, sfx_player_death, sfx_coin_gain

## 적 (13)

sfx_enemy_spawn, sfx_enemy_windup, sfx_enemy_swing, sfx_enemy_attack_land, sfx_enemy_hurt, sfx_enemy_death, sfx_charger_swing_windup, sfx_charger_swing_active, sfx_charger_dash_windup, sfx_charger_dash_go, sfx_wrestler_grab_windup, sfx_wrestler_miss_stun, sfx_porter_guard_block

## 보스 (8)

sfx_muneolgul_awaken, sfx_muneolgul_hit, sfx_muneolgul_face_switch, sfx_muneolgul_lean, sfx_muneolgul_slam, sfx_muneolgul_downed, sfx_muneolgul_door_slam, sfx_muneolgul_death

## 미니게임 (3)

sfx_ssireum_count, sfx_ssireum_go, sfx_ssireum_mash_hit

## 신당, 권능, 이벤트 (4)

sfx_shrine_enter, sfx_boon_grant_mongju, sfx_boon_grant, sfx_boon_cast

## UI와 시스템 (13)

sfx_gwimun_appear, sfx_gwimun_enter, ui_cursor_move, ui_confirm, ui_cancel, ui_pause_open, ui_pause_close, ui_map_unfold, ui_map_fold, ui_dialogue_open, ui_dialogue_type, ui_dialogue_advance, ui_scene_fade

## 선행 인프라 (사운드 큐 아님)

오디오 버스 4분리, 사운드 재생 오토로드, 볼륨 저장, 설정 UI 슬라이더 3종.
자세한 내용은 AUDIO_TONE_GUIDE.md 6장.
