# hgp 사운드 필요 목록

2026-08-10 기준. 1막 도깨비 시장 전체 (타이틀, 인트로, 허브 포함).
BGM은 레이어 분리 없이 완성된 한 곡으로 받는다.

현재 프로젝트에 오디오는 없다. 버스 설정, 재생 코드, 음량 설정 전부 없는 상태다.

---

# 1. BGM (14곡)

전부 루프. 길이는 1분 30초 ~ 2분 30초 기준. 방향은 국악 요소(장구, 피리, 방울) 중심.

| 파일명 | 나오는 곳 | 분위기 | 참고 이미지 |
|---|---|---|---|
| bgm_title | 타이틀 화면 | 저승 문턱의 정적. 대금과 낮은 징 | 01 |
| bgm_intro | 오프닝 컷툰 (7페이지) | 앞은 현대 이승의 무미건조함, 트럭 충돌 뒤 저승으로 완전히 바뀐다 | 02 |
| bgm_hub | 저승 접수청 (허브) | 관공서처럼 늘어진 무기력. 정적이고 사무적. 시장과 반대 톤 | 03 |
| bgm_act1_explore | 1막 이동 중 | 시장을 걷는 저강도 장단. 조용하고 성긴 타악 | 04 |
| bgm_act1_combat | 1막 전투 | 사물놀이 장단. 꽹과리 중심. 이 게임의 대표곡 | 04 |
| bgm_act1_rage | 생기 몰림 발동 후 | 전투곡을 통째로 대체. 등불이 적색으로 물들고 시간에 쫓기는 압박 | 04 |
| bgm_shrine | 신당 | 무속 정적. 방울과 잔향 긴 배음. 거리 소음이 사라진 공백감 | 05 |
| bgm_event | 이벤트방 | 결과를 감춘 긴장. 불규칙한 타점 | 04 |
| bgm_ssireum | 씨름판 | 장구 중심. 구호와 연타에 맞물리는 빠른 가락 | 09 |
| bgm_gamble | 노름판 | 등불 아래 나른하고 끈적한 밤 가락 | 10 |
| bgm_chase | 장물아비 추격 | 숨 가쁘게 몰아치는 추격. 발놀림에 맞춘 타악 | 11 |
| bgm_boss_muneolgul | 보스 문얼굴 | 수문신. 완고하고 무거운 태평소와 대북 | 08 |
| bgm_boss_bangmangi | 보스 방망이 | 심술궂은 요술쟁이. 경쾌하고 변덕스럽다 | 04 |
| bgm_result | 런 종료 화면 | 짧은 여운. 30초 내외 | 12 |

메모

- 지도 화면은 전용 곡 없이 재생 중인 곡을 낮게 눌러 쓴다
- 보스 페이즈가 바뀔 때는 곡 교체 없이 짧은 스팅어만 얹는다

---

# 2. 효과음

변형이 필요한 항목만 괄호에 개수를 적었다. 없으면 1종이다.

## 플레이어

| 파일명 | 언제 |
|---|---|
| sfx_player_footstep (4) | 달릴 때 발소리 |
| sfx_player_jump | 점프 |
| sfx_player_walljump | 벽 점프 |
| sfx_player_land | 착지 |
| sfx_player_dash | 대시 |
| sfx_player_dash_fail | 기력이 없어 대시가 안 나갈 때 |
| sfx_player_hurt (3) | 피격 |
| sfx_player_death | 사망 |

## 근접 (환도)

| 파일명 | 언제 |
|---|---|
| sfx_melee_swing_1 (2) | 1타 베기 |
| sfx_melee_swing_2 (2) | 2타 반대 베기 |
| sfx_melee_swing_3 (2) | 3타 마무리 내려베기. 가장 무겁게 |
| sfx_melee_air_swing (2) | 공중 내려찍기 |
| sfx_melee_hit (4) | 적에게 맞았을 때. 게임에서 가장 자주 들린다 |
| sfx_melee_hit_finisher (2) | 마무리 타가 맞았을 때 |
| sfx_guard_blocked (3) | 적 가드에 튕겼을 때. 명중음과 확실히 달라야 한다 |

## 총

| 파일명 | 언제 |
|---|---|
| sfx_rifle_fire (4) | 발사. 0.16초 연사라 반복이 매우 잦다 |
| sfx_rifle_last_round | 마지막 한 발 |
| sfx_rifle_reload_start (2) | 장전 시작 |
| sfx_rifle_reload_finish (2) | 장전 완료 |
| sfx_bullet_impact_flesh (3) | 적 명중 |
| sfx_bullet_impact_wall (3) | 벽 착탄 |

## 적 공통

| 파일명 | 언제 |
|---|---|
| sfx_enemy_spawn (3) | 등장 |
| sfx_enemy_step (3) | 발소리 |
| sfx_enemy_windup (3) | 공격 예비. 회피 판단의 근거라 어택이 빨라야 한다 |
| sfx_enemy_swing (3) | 공격 발동 |
| sfx_enemy_attack_land (3) | 플레이어에게 맞췄을 때 |
| sfx_enemy_hurt (3) | 피격 |
| sfx_enemy_death (3) | 처치 |
| sfx_enemy_hit_armored (2) | 슈퍼아머라 안 밀릴 때 |

## 적 개체별 (6종)

| 파일명 | 언제 |
|---|---|
| sfx_charger_dash_windup (2) | 잡도깨비 돌진 예고. 웅크림 |
| sfx_charger_dash_go (2) | 잡도깨비 돌진 |
| sfx_charger_bonk (2) | 잡도깨비 벽에 머리 박음. 우스꽝스럽게 |
| sfx_lantern_windup (2) | 등불 도깨비 투척 예고 |
| sfx_lantern_throw (3) | 등불 도깨비 투척 |
| sfx_lantern_ignite (3) | 착탄해서 불붙음 |
| sfx_lantern_burn_loop | 화염 지대 지속 (루프) |
| sfx_fence_snatch (2) | 장물아비 낚아채기 |
| sfx_fence_steal (2) | 엽전 강탈 성공 |
| sfx_fence_burrow | 장물아비 땅 파고 도주 (루프) |
| sfx_wrestler_grab_windup (2) | 씨름꾼 그랩 예비. 도약 예비와 구분되어야 한다 |
| sfx_wrestler_throw (2) | 씨름꾼 배지기 |
| sfx_wrestler_miss_stun (2) | 씨름꾼이 빗나가 벽에 박힘. 반격 기회 신호 |
| sfx_egg_roll_loop | 달걀도깨비 구르기 (루프) |
| sfx_egg_bounce (3) | 달걀도깨비 벽에 튕김 |
| sfx_porter_guard_block (3) | 짐꾼 정면 가드에 막힘 |
| sfx_porter_cargo_break (2) | 짐꾼 짐 파괴. 가드가 사라지는 순간 |

## 보스 문얼굴

| 파일명 | 언제 |
|---|---|
| sfx_muneolgul_awaken | 개전. 대문이 깨어난다 |
| sfx_muneolgul_hit (4) | 피격. 석재를 때리는 둔중함 |
| sfx_muneolgul_face_switch (2) | 좌우 얼굴 전환. 다음 패턴 예고 단서 |
| sfx_muneolgul_quake | 지진. 대문이 들썩임 |
| sfx_muneolgul_rock_fall (3) | 낙석 낙하 |
| sfx_muneolgul_rock_shatter (4) | 낙석이 바닥에서 부서짐 |
| sfx_muneolgul_lean | 앞으로 기울어짐. 회피 판단 구간 |
| sfx_muneolgul_slam | 바닥에 넘어짐. 전투 최대 저역 |
| sfx_muneolgul_downed | 약점 노출. 딜 창 시작 |
| sfx_muneolgul_beam_fire (2) | 눈에서 광선 발사 |
| sfx_muneolgul_door_open | 문짝 열림 |
| sfx_muneolgul_door_slam | 문짝 닫힘. 소환 국면의 끝 |
| sfx_muneolgul_wind_loop | 강풍 지속 (루프) |
| sfx_muneolgul_obstacle (3) | 궤짝과 항아리 투척 |
| sfx_muneolgul_death | 처치. 대문 붕괴 |

## 보스 방망이

| 파일명 | 언제 |
|---|---|
| sfx_bangmangi_cast_fire (3) | 도깨비불 소환 |
| sfx_bangmangi_treasure_fall (3) | 재물 낙하 |
| sfx_bangmangi_smash_windup (2) | 난타 예비 |
| sfx_bangmangi_smash (3) | 난타 |
| sfx_bangmangi_death | 처치 |

## 신당과 권능

| 파일명 | 언제 |
|---|---|
| sfx_shrine_enter | 신당 진입. 방울 한 번 |
| sfx_shrine_offer | 권능 3택 제시 |
| sfx_shrine_reroll (2) | 무당 방울로 재추첨 |
| sfx_boon_grant_mongju | 몸주 결정. 런에서 한 번뿐 |
| sfx_boon_grant (3) | 권능 획득. 등급별 |
| sfx_boon_cast | 권능 발동 공통 |
| sfx_fusion_success | 권능 융합 성공 |
| sfx_fusion_great | 융합 대성공. 런에서 가장 화려하게 |
| sfx_fusion_fail | 융합 실패 |

## 미니게임

| 파일명 | 언제 |
|---|---|
| sfx_ssireum_satba (3) | 씨름 샅바 잡기 |
| sfx_ssireum_count (3) | 구호 3, 2, 1. 음정 상승 |
| sfx_ssireum_go | 시작. 꽹과리 한 방 |
| sfx_ssireum_mash_hit (4) | 연타 성공. 가장 빠르게 반복된다 |
| sfx_ssireum_mash_miss (3) | 연타 실패 |
| sfx_ssireum_throw (2) | 메다꽂기 |
| sfx_crowd_cheer (2) | 관중 환호 |
| sfx_crowd_groan (2) | 관중 탄식 |
| sfx_gamble_bet (3) | 판돈 걸기 |
| sfx_gamble_deal (4) | 패 돌리기 |
| sfx_gamble_flip (4) | 패 뒤집기 |
| sfx_gamble_dice_shake | 주사위 흔들기 (루프) |
| sfx_gamble_dice_roll (3) | 주사위 굴러 멈춤 |
| sfx_gamble_win | 승리 |
| sfx_gamble_lose | 패배 |
| sfx_chase_footsteps | 추격 달리기 (루프) |
| sfx_chase_lane_shift (3) | 레인 이동 |
| sfx_chase_obstacle_hit (4) | 궤짝과 항아리 충돌 |
| sfx_chase_lamp_out (3) | 등불 하나 꺼짐. 남은 기회 신호 |
| sfx_chase_catch (3) | 장물아비 포착 |

## 환경

| 파일명 | 언제 |
|---|---|
| sfx_gwimun_appear | 귀문 출현. 방 클리어 보상 신호 |
| sfx_gwimun_enter | 귀문 통과 |
| sfx_stall_hit (3) | 좌판 피격 |
| sfx_stall_break (3) | 좌판 파괴 |
| sfx_lantern_switch (2) | 등불 스위치 점등 |
| sfx_wisp_light (2) | 도깨비불 발판 점등 |
| sfx_wisp_blink | 발판 꺼지기 직전 경고 (루프) |
| sfx_wisp_out (2) | 발판 소등 |
| sfx_coin_gain (3) | 엽전 획득 |
| sfx_relic_gain (2) | 유물 획득 |
| sfx_npc_startled (3) | 허브 NPC 놀람 |

## 앰비언스 (루프 4종)

| 파일명 | 언제 |
|---|---|
| amb_act1_street | 좌판 거리. 시장 소음 베드 |
| amb_act1_alley | 골목. 좁은 반향, 소음이 벽 너머로만 |
| amb_shrine | 신당. 바람과 촛불 |
| amb_hub_office | 접수청. 웅얼거림, 도장 찍는 소리 |

## UI

| 파일명 | 언제 |
|---|---|
| ui_cursor_move (2) | 커서 이동 |
| ui_confirm | 확정. 도장 찍는 느낌 |
| ui_cancel | 취소 |
| ui_pause_open | 일시정지 열기 |
| ui_pause_close | 일시정지 닫기 |
| ui_map_unfold | 지도 펼치기 |
| ui_map_fold | 지도 접기 |
| ui_dialogue_type (3) | 대화 글자 출력. 아주 작고 짧게 |
| ui_dialogue_advance | 대화 다음 줄 |
| ui_popup_show | 결과 팝업 |
| ui_scene_fade | 씬 전환 암전 |

## 스팅어

| 파일명 | 언제 |
|---|---|
| stg_run_start | 런 시작. 상행문 통과 |
| stg_room_clear | 방 클리어 |
| stg_rage_warning | 생기 몰림 경고. 1초 간격 반복 |
| stg_rage_trigger | 생기 몰림 발동. bgm_act1_rage로 넘어감 |
| stg_boss_phase | 보스 페이즈 전환 |
| stg_boss_defeat | 보스 처치 |
| stg_run_fail | 사망. 음악을 끊고 정적으로 |

---

# 3. 규격

| 항목 | 값 |
|---|---|
| BGM, 앰비언스 | .ogg, 스테레오, 44.1kHz, 심리스 루프 |
| 효과음, UI | .wav 16bit, 모노 (UI만 스테레오 허용), 44.1kHz |
| 파일명 | 소문자 snake_case. 변형은 뒤에 두 자리 (예: sfx_melee_hit_01) |
| 넣을 위치 | assets/audio/ 아래 bgm, amb, sfx, ui |

# 4. 개수

| 분류 | 항목 수 | 변형 포함 클립 수 |
|---|---|---|
| BGM | 14 | 14 |
| 효과음 | 103 | 약 200 |

# 5. 코드가 먼저 필요한 것

| 항목 | 이유 |
|---|---|
| 오디오 버스 4분리 (음악, 앰비언스, 효과음, UI) | project.godot에 오디오 설정 자체가 없다 |
| 사운드 재생 오토로드 | 재생 계층이 없다 |
| 음량 설정 3종 | 설정 화면이 뒤로가기 버튼만 있는 빈 껍데기다 |
| 발소리 훅 | 발이 땅에 닿는 프레임 신호가 없다 |
| 저체력 경고 판정 | 체력 임계값 판정이 없다 |

패링 관련 소리는 시스템 자체가 미구현이라 이번 목록에서 뺐다.

# 6. 이미지

| 번호 | 파일 | 용도 |
|---|---|---|
| 01 | 01_ingame.png | 실제 인게임 화면. 밀도와 톤 기준 |
| 02 | 02_intro.png | 오프닝. 저승사자 대면 |
| 03 | 03_hub.png | 허브 접수청 |
| 04 | 04_act1_street.png | 1막 좌판 거리 무드 기준 |
| 05 | 05_shrine.png | 신당 두 종 |
| 06 | 06_player.png | 플레이어 동작 전체 |
| 07 | 07_enemies.png | 적 도깨비 |
| 08 | 08_boss_muneolgul.png | 보스 문얼굴 |
| 09 | 09_ssireum.png | 씨름판 |
| 10 | 10_gamble.png | 노름판 |
| 11 | 11_chase.png | 추격 |
| 12 | 12_map.png | 노드 지도 화면 |
