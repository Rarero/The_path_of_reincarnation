# M1 Windows 작업 체크리스트 (폐기)

폐기 (2026-07-29): 개발 환경이 Mac으로 전환됐다. 이 문서는 docs/M1_CHECKLIST.md로 대체됐다. 커밋 시 이 파일은 삭제한다.

최종 수정: 2026-07-27
목적: Cowork(Mac)에서 작성한 M1 스켈레톤을 Windows 개발 환경에서 바로 실행하고 튜닝하기 위한 절차와 검증 항목.
관련 문서: docs/PROTOTYPE.md (범위와 통과 기준), docs/ROOM_SPEC.md (방 규격), docs/HARNESS.md (검증 3계층)

## 0. 전제

- 환경 설치가 끝나 있어야 한다. 백지 상태라면 docs/WINDOWS_SETUP.md를 먼저 1장부터 수행한다
- Godot 4.6.3-stable 설치 (버전 고정 근거는 docs/HARNESS.md)
- 저장소 최신 pull
- Mac 환경에서 python tools/check.py 통과 확인됨. 엔진 로딩과 플레이는 미검증 상태다

## 1. 최초 실행 절차

1. Godot 4.6.3으로 프로젝트를 연다. 첫 임포트 시 .godot 캐시와 .uid 파일이 생성된다
2. 출력 로그에서 스크립트 파싱 에러와 씬 로드 경고를 확인한다. 에러가 있으면 여기서 멈추고 내용을 정리해 Cowork에 전달한다
3. F5로 실행한다. 메인 씬은 res://scenes/levels/stage_verify.tscn (검증용 방 2개)
4. 1막 러프 6방 구성은 res://scenes/levels/stage_act1_rough.tscn을 직접 열어 F6으로 실행한다
5. 에디터 하단 gdUnit4 패널에서 tests/unit 전체를 실행해 5개 스위트가 통과하는지 확인한다
6. 첫 임포트로 생성된 .uid와 .godot 외 산출물 중 커밋 대상(.uid)을 커밋한다

## 2. 조작

| 동작 | 키보드 | 게임패드 |
|---|---|---|
| 이동 | A / D, 좌우 화살표 | 왼쪽 스틱, D패드 |
| 조준 (상하) | W / S | (미할당) |
| 점프 | Space | A |
| 총 사격 | K | RB |
| 총검 | J | X |
| 재장전 | R | Y |
| 대시 | Shift | LB |
| 즉시 재시작 | F5 | Start |

- 사격은 바라보는 방향으로 나가고, W나 S를 누른 상태에서는 8방향으로 꺾인다 (S는 공중에서만)
- 게임패드 아날로그 스틱 조준은 미할당이다. 필요하면 에디터 입력 맵에서 추가한다

## 3. 실행 직후 확인 (스모크)

- [ ] 파싱 에러, 씬 로드 에러 없음
- [ ] 플레이어가 첫 방 좌측에 스폰되고 HUD에 체력, 스태미나, 탄약이 표시된다
- [ ] 이동, 점프, 벽 점프, 대시가 동작한다
- [ ] 총 사격으로 적을 처치할 수 있고 8발 소진 후 재장전이 걸린다
- [ ] 총검이 근접 판정을 낸다
- [ ] 적 2종이 각각 돌진과 원거리 사격으로 반응한다
- [ ] 방의 적을 전멸시키면 HUD에 클리어 시간이 표시된다 (로그에도 [room_cleared] 출력)
- [ ] 문 개구부로 다음 방에 넘어갈 수 있다
- [ ] 사망 시 1.2초 후 씬이 재시작된다
- [ ] 방 밖으로 떨어지면 가까운 방 스폰 지점으로 복귀하고 체력 10을 잃는다
- [ ] 전투 시작 후 80초쯤에 HUD에 "생기가 고인다 N초" 경고가 뜬다 (2026-07-29 추가)
- [ ] 적을 남기고 다음 방으로 넘어가면 이전 방의 생기 몰림 표시가 사라진다 (2026-07-29 추가)
- [ ] 발판 위의 등불 도깨비가 거리 조절 중에 발판 밖으로 떨어지지 않는다 (2026-07-29 추가)

## 4. 통과 기준 판정 (docs/PROTOTYPE.md 5장)

| 번호 | 기준 | 판정 | 메모 |
|---|---|---|---|
| 1 | 조작 반응 (코요테, 버퍼, 가변 점프) | | |
| 2 | 속도감 (전투방 1개 60~90초) | | |
| 3 | 전투 리듬 (재장전과 총검 전환) | | |
| 4 | 반복 내성 (10분 반복) | | |
| 5 | 데스매치 체감 (90초 발동) | | |

- 1, 2, 3은 필수. 4, 5는 수치 튜닝으로 개선 가능하면 조건부 통과
- 판정 결과와 메모를 docs/PROGRESS.md에 기록한다

## 5. 튜닝 지점 (전부 @export, 에디터에서 즉시 조정)

| 대상 | 노드 / 파일 | 주요 파라미터 |
|---|---|---|
| 이동과 점프 | Player (scenes/player/player.tscn) | max_speed, ground_accel, air_accel, jump_height_tiles, time_to_peak, time_to_descent, jump_cut, coyote_time, jump_buffer |
| 벽과 회피 | Player | wall_jump_push, wall_slide_speed, roll_speed, roll_duration, roll_stamina_cost, dash_speed, dash_duration, dash_recovery |
| 스태미나 | Player/Stamina | maximum, regen_per_second, regen_delay |
| 총과 총검 | Player/Rifle | magazine_size, fire_interval, reload_time, bullet_damage, bullet_speed, melee_windup, melee_recovery |
| 총검 판정 | Player/Rifle/MeleeHitbox | damage, active_duration |
| 적 수치 | resources/enemies/*.tres | max_health, move_speed, contact_damage, detect_range, attack_cooldown, hitstun |
| 돌진 | EnemyCharger | charge_speed_multiplier, charge_duration |
| 원거리 | EnemyShooter | preferred_range(0이면 .tres의 attack_range 사용), range_tolerance, bullet_damage, bullet_speed, aim_height |
| 생기 몰림 | 각 Room 노드 | rage_threshold, rage_step_interval, rage_warning_window |
| 낙사 처리 | Stage | fall_limit_y, fall_damage |

- jump_height_tiles 등 점프 값을 바꾼 뒤 실행하면 물리값이 자동 파생된다 (scripts/systems/jump_math.gd)
- 적 수치는 .tres가 권위다. 씬의 Health.maximum은 런타임에 .tres 값으로 덮인다

## 6. 미검증 위험 지점 (Windows에서 먼저 볼 것)

1. project.godot 입력 맵을 텍스트로 직접 작성했다. 액션 11개가 에디터 입력 맵에 정상 표시되는지 확인한다
2. 씬 파일을 텍스트로 작성했다. load_steps와 노드 프로퍼티 오류는 로드 시 경고로 드러난다
3. 도형 지형(Block)은 @tool 스크립트로 크기를 반영한다. 에디터에서 블록이 보이지 않으면 스크립트 재컴파일(파일 저장) 후 확인한다
4. 방 규격의 도달 가능성은 계산값(수직 48px, 수평 96px 이하) 기준이다. 실제 플레이에서 넘지 못하는 지점이 있으면 docs/ROOM_SPEC.md 4장 수치를 갱신한다
5. 근접 판정은 활성화 다음 프레임부터 겹침을 검사한다. 체감상 늦으면 melee_windup을 줄인다

## 7. 완료 후

- [ ] 통과 기준 판정 결과를 docs/PROGRESS.md에 기록
- [ ] 튜닝으로 바뀐 수치를 커밋 (씬과 .tres 변경)
- [ ] 로드 에러나 설계 결함이 있으면 목록으로 정리해 Cowork 세션에 전달
- [ ] 통과 시 ROADMAP M1 항목 체크, 미통과 시 M0 회귀 판단
