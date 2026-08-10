extends GdUnitTestSuite

## 총 해금과 시작 무기 선택 검증 (docs/systems/WEAPONS.md 11장).
##
## 총은 시작 무기에서 빠져 있고 대장장이 도깨비 대화로만 열린다. 해금 전에는
## 총을 고를 수 없어야 하고, 해금 뒤에는 선택이 디스크를 왕복해야 한다.
## GameState는 오토로드라 각 테스트 앞뒤로 초기화해 서로 간섭하지 않게 한다.


func before_test() -> void:
	GameState.clear_meta()
	GameState.reset_all()


func after_test() -> void:
	GameState.clear_meta()
	GameState.reset_all()


func _drain(box: DialogueBox) -> void:
	var steps: int = 0
	while box.is_active() and steps < 64:
		box._advance()
		steps += 1


func _new_box() -> DialogueBox:
	var box: DialogueBox = auto_free(DialogueBox.new())
	add_child(box)
	return box


## 기본 시작 무기는 환도이고 총은 잠겨 있다 (11.1절).
func test_default_start_weapon_is_hwando() -> void:
	assert_bool(GameState.gun_unlocked).is_false()
	assert_str(GameState.start_weapon).is_equal(GameState.WEAPON_HWANDO)
	assert_bool(GameState.starts_with_gun()).is_false()


## 해금 전에는 총을 고를 수 없다. 넣어도 환도로 되돌아간다.
func test_gun_cannot_be_selected_before_unlock() -> void:
	GameState.set_start_weapon(GameState.WEAPON_GUN)
	assert_str(GameState.start_weapon).is_equal(GameState.WEAPON_HWANDO)
	GameState.toggle_start_weapon()
	assert_str(GameState.start_weapon).is_equal(GameState.WEAPON_HWANDO)


## 해금 자체는 무기를 바꾸지 않는다. 무엇을 들지는 따로 고른다 (11.3절).
func test_unlock_does_not_change_start_weapon() -> void:
	GameState.unlock_gun()
	assert_bool(GameState.gun_unlocked).is_true()
	assert_str(GameState.start_weapon).is_equal(GameState.WEAPON_HWANDO)


## 해금 뒤에는 환도와 총을 번갈아 고를 수 있다.
func test_toggle_after_unlock() -> void:
	GameState.unlock_gun()
	GameState.toggle_start_weapon()
	assert_str(GameState.start_weapon).is_equal(GameState.WEAPON_GUN)
	assert_bool(GameState.starts_with_gun()).is_true()
	GameState.toggle_start_weapon()
	assert_str(GameState.start_weapon).is_equal(GameState.WEAPON_HWANDO)
	assert_bool(GameState.starts_with_gun()).is_false()


## 해금과 선택이 디스크를 왕복한다. 사망 후에도 유지되려면 이게 성립해야 한다.
func test_weapon_state_round_trip() -> void:
	GameState.unlock_gun()
	GameState.set_start_weapon(GameState.WEAPON_GUN)

	GameState.gun_unlocked = false
	GameState.start_weapon = GameState.WEAPON_HWANDO
	GameState.load_meta()

	assert_bool(GameState.gun_unlocked).is_true()
	assert_str(GameState.start_weapon).is_equal(GameState.WEAPON_GUN)


## 손상된 저장이 해금 없이 총을 들고 있으면 환도로 되돌린다.
func test_load_repairs_gun_without_unlock() -> void:
	var file: FileAccess = FileAccess.open(GameState.META_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"gun_unlocked": false, "start_weapon": "gun"}))
	file.close()
	GameState.load_meta()
	assert_str(GameState.start_weapon).is_equal(GameState.WEAPON_HWANDO)


## 처음부터(타이틀)와 디버그 초기화는 총 해금까지 되돌린다.
func test_reset_clears_gun_unlock() -> void:
	GameState.unlock_gun()
	GameState.set_start_weapon(GameState.WEAPON_GUN)
	GameState.reset_all()
	assert_bool(GameState.gun_unlocked).is_false()
	assert_str(GameState.start_weapon).is_equal(GameState.WEAPON_HWANDO)


## 대장장이 해금 대화의 마지막 줄에서 해금 훅이 정확히 한 번 발생한다.
func test_smith_dialogue_fires_unlock_once() -> void:
	var box: DialogueBox = _new_box()
	var fired: Array[String] = []
	box.effect_fired.connect(func(effect: String) -> void: fired.append(effect))
	box.open(HubLines.SMITH_GUN)
	_drain(box)
	assert_array(fired).contains_exactly(["unlock_gun"])


## 교체 대화는 교체 훅을 낸다. 대화 자체가 곧 교체다.
func test_smith_swap_dialogue_fires_swap() -> void:
	var box: DialogueBox = _new_box()
	var fired: Array[String] = []
	box.effect_fired.connect(func(effect: String) -> void: fired.append(effect))
	box.open(HubLines.SMITH_SWAP)
	_drain(box)
	assert_array(fired).contains_exactly(["swap_weapon"])


## 대사 분량은 허브 규격 상한(대화 6줄, 대사 70자) 안에 있다 (DESIGN_HUB 5.2절).
func test_smith_line_budget_within_cap() -> void:
	for conversation: Dictionary in [HubLines.SMITH_GUN, HubLines.SMITH_SWAP]:
		assert_int((conversation["lines"] as Array).size()).is_less_equal(6)
		for line: Dictionary in conversation["lines"] as Array:
			assert_int(String(line["text"]).length()).is_less_equal(70)
