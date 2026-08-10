extends GdUnitTestSuite

## 허브 시작 흐름 검증 (docs/DESIGN_HUB.md 5.3~5.7절, G12).
##
## 첫 런 게이팅 두 조건, meta.json 저장과 로드 왕복, 대화 진행 상태 기계,
## 이후 런 대사 선택 우선순위를 본다.
## GameState는 오토로드라 테스트가 전역 상태를 건드린다. 각 테스트 앞뒤로
## 초기화해 서로 간섭하지 않게 한다.

const CHASA_INTRO_LINES: int = 6


func before_test() -> void:
	GameState.clear_meta()
	GameState.reset_all()


func after_test() -> void:
	GameState.clear_meta()
	GameState.reset_all()


func _drain(box: DialogueBox) -> int:
	# 한 줄당 두 번 눌러 넘긴다(타자 즉시 노출 + 다음 줄). 5.2절 2단 입력
	var steps: int = 0
	while box.is_active() and steps < 64:
		box._advance()
		steps += 1
	return steps


func _new_box() -> DialogueBox:
	var box: DialogueBox = auto_free(DialogueBox.new())
	add_child(box)
	return box


## 첫 런은 두 조건을 모두 만족해야 상행문이 열린다.
func test_first_run_gate_needs_both_conditions() -> void:
	assert_bool(GameState.can_depart()).is_false()
	GameState.mark_chasa_intro_done()
	assert_bool(GameState.can_depart()).is_false()
	GameState.mark_map_received()
	assert_bool(GameState.can_depart()).is_true()


## 잠김 사유는 미충족 조건을 차사 먼저 가리킨다 (편도 동선 순서).
func test_block_reason_points_to_chasa_first() -> void:
	assert_str(GameState.depart_block_reason()).contains("차사")
	GameState.mark_chasa_intro_done()
	assert_str(GameState.depart_block_reason()).contains("창구")
	GameState.mark_map_received()
	assert_str(GameState.depart_block_reason()).is_empty()


## 플래그가 디스크를 왕복한다. 사망 후에도 유지되려면 이게 성립해야 한다.
func test_meta_save_load_round_trip() -> void:
	GameState.mark_chasa_intro_done()
	GameState.mark_map_received()
	GameState.advance_run_count()
	GameState.advance_run_count()
	GameState.mark_line_seen("chasa_r1")

	# 메모리만 비우고 파일에서 되살린다
	GameState.chasa_intro_done = false
	GameState.map_received = false
	GameState.run_count = 0
	GameState.seen_lines.clear()
	GameState.load_meta()

	assert_bool(GameState.chasa_intro_done).is_true()
	assert_bool(GameState.map_received).is_true()
	assert_int(GameState.run_count).is_equal(2)
	assert_bool(GameState.has_seen_line("chasa_r1")).is_true()


## 저장 파일이 없으면 기본값을 유지한다(첫 실행).
func test_meta_load_without_file_keeps_defaults() -> void:
	GameState.clear_meta()
	GameState.load_meta()
	assert_bool(GameState.chasa_intro_done).is_false()
	assert_int(GameState.run_count).is_equal(0)


## 대화는 줄 수만큼 진행하고 끝나면 닫힌다.
func test_dialogue_advances_through_all_lines() -> void:
	var box: DialogueBox = _new_box()
	box.open(HubLines.CHASA_INTRO)
	assert_bool(box.is_active()).is_true()
	_drain(box)
	assert_bool(box.is_active()).is_false()


## 마지막 줄에서 환도 지급 훅이 정확히 한 번 발생한다.
func test_chasa_intro_fires_sword_effect_once() -> void:
	var box: DialogueBox = _new_box()
	var fired: Array[String] = []
	box.effect_fired.connect(func(effect: String) -> void: fired.append(effect))
	box.open(HubLines.CHASA_INTRO)
	_drain(box)
	assert_array(fired).contains_exactly(["grant_sword"])


## 대화 완료 시그널이 대화 id를 실어 온다. hub.gd가 이걸로 플래그를 세운다.
func test_dialogue_finished_carries_id() -> void:
	var box: DialogueBox = _new_box()
	var got: Array[String] = []
	box.finished.connect(func(id: String) -> void: got.append(id))
	box.open(HubLines.CLERK_MAP)
	_drain(box)
	assert_array(got).contains_exactly(["clerk_map"])


## 열려 있는 동안 다시 열어도 무시한다(중복 진입 방지).
func test_dialogue_ignores_reopen_while_active() -> void:
	var box: DialogueBox = _new_box()
	box.open(HubLines.CHASA_INTRO)
	box.open(HubLines.CLERK_MARKS)
	var got: Array[String] = []
	box.finished.connect(func(id: String) -> void: got.append(id))
	_drain(box)
	assert_array(got).contains_exactly(["chasa_intro"])


## 게이팅 대화는 건너뛸 수 없고, 설명 대화는 건너뛸 수 있다 (5.2절).
func test_skippable_flags_match_design() -> void:
	assert_bool(bool(HubLines.CHASA_INTRO["skippable"])).is_false()
	assert_bool(bool(HubLines.CLERK_MAP["skippable"])).is_false()
	assert_bool(bool(HubLines.CLERK_MARKS["skippable"])).is_true()
	assert_bool(bool(HubLines.CLERK_ROUTE["skippable"])).is_true()


## 확정 대사 분량이 5.2절 상한(대화 6줄, 대사 70자) 안에 있다.
func test_line_budget_within_cap() -> void:
	for conversation: Dictionary in [
		HubLines.CHASA_INTRO,
		HubLines.CLERK_MAP,
		HubLines.CLERK_MARKS,
		HubLines.CLERK_ROUTE,
		HubLines.SMITH_GUN,
		HubLines.SMITH_SWAP,
	]:
		assert_int((conversation["lines"] as Array).size()).is_less_equal(6)
		for line: Dictionary in conversation["lines"] as Array:
			assert_int(String(line["text"]).length()).is_less_equal(70)


## 지도를 받은 뒤 반복 설명은 이동 규칙을 먼저 낸다. 갓 지도를 받은 참에
## 알아야 할 것은 길 고르는 법이지 기호 범례가 아니다 (5.5절).
func test_clerk_explains_route_first() -> void:
	var entries: Array = HubLines.CLERK_EXPLAIN
	assert_int(entries.size()).is_greater(1)
	assert_str(String((entries[0] as Dictionary)["id"])).is_equal("clerk_route")


## 이동 규칙 설명이 자유 이동과 명줄을 모두 짚는다 (RUN_STRUCTURE 11장).
## 규칙을 빠뜨린 채 문구만 다듬는 개정을 막는다.
##
## 2026-08-09: 검사 낱말을 갱신했다. 종전의 "갑절"(후퇴 배수)과 "관문"(일방통행)은
## 2026-08-06 자유 이동 전환에서 폐기된 규칙인데, 그 낱말을 요구하는 검사가
## 폐기된 규칙을 대사에 붙잡아 두고 있었다. 이제는 반대로 되살아나는 것을 막는다
func test_route_lines_cover_movement_rules() -> void:
	var joined: String = ""
	for line: Dictionary in HubLines.CLERK_ROUTE["lines"] as Array:
		joined += String(line["text"])
	for keyword: String in ["명줄", "되짚", "이어진"]:
		assert_str(joined).contains(keyword)
	for banned: String in ["갑절", "관문", "한 층"]:
		assert_bool(joined.contains(banned)).is_false()


## 1회성 대사는 소진 처리되면 다시 나오지 않는다 (5.6절).
func test_seen_line_is_consumed() -> void:
	assert_bool(GameState.has_seen_line("chasa_r1")).is_false()
	GameState.mark_line_seen("chasa_r1")
	assert_bool(GameState.has_seen_line("chasa_r1")).is_true()
	GameState.mark_line_seen("chasa_r1")
	assert_int(GameState.seen_lines.size()).is_equal(1)


## 진행도 해금은 임계값을 넘어야 열린다. 목록은 큰 값부터 정렬돼 있어야
## run_count가 높을 때 가장 높은 단계가 먼저 걸린다.
func test_milestones_sorted_descending() -> void:
	var previous: int = 999
	for entry: Dictionary in HubLines.CHASA_MILESTONES:
		var runs: int = int(entry["runs"])
		assert_int(runs).is_less_equal(previous)
		previous = runs


## 런 시작마다 run_count가 오르고 그대로 저장된다 (6장).
func test_run_count_advances_and_persists() -> void:
	GameState.advance_run_count()
	GameState.advance_run_count()
	GameState.advance_run_count()
	assert_int(GameState.run_count).is_equal(3)
	GameState.run_count = 0
	GameState.load_meta()
	assert_int(GameState.run_count).is_equal(3)


## 디버그 초기화는 저장 파일까지 지운다. 첫 런 흐름 반복 검증에 필요하다.
func test_reset_clears_meta_file() -> void:
	GameState.mark_chasa_intro_done()
	GameState.reset_all()
	assert_bool(FileAccess.file_exists(GameState.META_PATH)).is_false()
	assert_bool(GameState.chasa_intro_done).is_false()
