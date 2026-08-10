extends Room

## 신당 방 (docs/systems/BOONS.md 7장, docs/DESIGN_ACT1.md 3.3).
##
## 진입하면 3택 패널을 연다. 첫 신당은 몸주와 액티브, 이후 신당은 권능 하나를 준다.
## 권능 신당에서 3칸이 차 있으면 버리기/조합/포기 하위 메뉴로 이어진다 (7장 규칙 6).
## shrine_reroll 키는 권능 신당 한정, 신당당 1회 재추첨이다 (규칙 37). shrine_fuse
## 키는 보유 액티브/권능을 자유롭게 조합하는 메뉴를 연다. 조합은 신당 안에서만
## 연다 (5장). 선택 중에는 게임을 멈춘다.

enum Mode {
	IDLE,
	OFFER,
	CAPACITY,
	CAPACITY_DISCARD,
	CAPACITY_FUSE_PICK,
	FUSION_PICK_MAIN,
	FUSION_PICK_SUB,
	FUSION_CONFIRM,
}

var _opened: bool = false
var _mode: int = Mode.IDLE
var _offer: Dictionary = {}
var _rerolled: bool = false
var _pending_boon: BoonDef = null
var _fusion_main_ref: int = -2
var _fusion_sub_ref: int = -2
var _fusion_main_refs: Array[int] = []
var _fusion_sub_refs: Array[int] = []
var _seed_counter: int = 0

@onready var _notice: Label = get_node_or_null(^"Notice/Text") as Label
@onready var _panel: ShrinePanel = get_node_or_null(^"ShrineUi/ShrinePanel") as ShrinePanel
@onready var _candle_l: LanternLight = get_node_or_null(^"Lights/CandleTealL") as LanternLight
@onready var _candle_r: LanternLight = get_node_or_null(^"Lights/CandleTealR") as LanternLight
@onready var _moon_shaft: LanternLight = get_node_or_null(^"Lights/MoonShaft") as LanternLight


func _ready() -> void:
	super()
	zone.body_entered.connect(_on_shrine_entered)
	if _panel != null:
		_panel.chosen.connect(_on_choice)
		_panel.cancelled.connect(_on_cancel)
		_panel.reroll_requested.connect(_try_reroll)


## 조합 메뉴 열기만 여기서 받는다. 선택 중에는 트리가 멈춰 있고 이 방 노드는
## PROCESS_MODE_INHERIT이라 입력이 오지 않으므로, 멈춘 동안 필요한 재추첨 입력은
## ShrinePanel(PROCESS_MODE_ALWAYS)이 받아 reroll_requested로 넘겨준다.
func _unhandled_input(event: InputEvent) -> void:
	if not _opened:
		return
	if event.is_action_pressed(&"shrine_fuse"):
		_try_open_fusion_menu()


func _on_shrine_entered(body: Node2D) -> void:
	if _opened or not body.is_in_group(&"player"):
		return
	# 되짚어 온 신당은 아무것도 주지 않는다. 신당은 1회성이다
	# (docs/RUN_STRUCTURE.md 11.5). _opened는 인스턴스 변수라 방을 다시 만들면
	# 늘 false가 되고, 이 검사가 없으면 왕복만으로 권능을 무한히 받을 수 있다
	if is_empty_room():
		_set_notice("이미 다녀간 신당")
		return
	_opened = true
	_start_offer()


## 신당 3택을 새로 굴려 연다 (진입 시 1회, 재추첨 시 다시 호출).
func _start_offer() -> void:
	_offer = RunState.roll_shrine(_next_seed())
	_rerolled = false
	var kind: String = String(_offer.get("kind", "none"))
	if kind == "none" or _panel == null:
		_set_notice("받을 것이 없다")
		return
	_mode = Mode.OFFER
	_open_offer_panel()


func _open_offer_panel() -> void:
	var kind: String = String(_offer.get("kind", "none"))
	var title: String = "몸주를 정하라" if kind == "mongju" else "권능을 고르라"
	var can_reroll: bool = kind == "boon" and not _rerolled and RunState.can_reroll_shrine()
	get_tree().paused = true
	_panel.open(
		title,
		_label_array(_offer.get("labels", []) as Array),
		_offer_info_text(kind),
		[],
		"",
		false,
		can_reroll
	)


## 권능 신당에서만 재추첨 안내를 보여준다. 몸주 신당(kind==mongju)은 규칙 37로 재추첨이 없다.
func _offer_info_text(kind: String) -> String:
	if kind != "boon":
		return ""
	if _rerolled:
		return "무당 방울 %d개. 재추첨은 신당당 1회다" % RunState.divination_bells
	if RunState.can_reroll_shrine():
		return "무당 방울 %d개. T로 재추첨" % RunState.divination_bells
	return "무당 방울 %d개" % RunState.divination_bells


func _try_reroll() -> void:
	if _mode != Mode.OFFER or String(_offer.get("kind", "none")) != "boon":
		return
	if _rerolled or not RunState.can_reroll_shrine():
		return
	var rerolled_offer: Dictionary = RunState.reroll_shrine(_next_seed())
	if String(rerolled_offer.get("kind", "none")) == "none":
		return
	_offer = rerolled_offer
	_rerolled = true
	_open_offer_panel()


func _on_choice(index: int) -> void:
	match _mode:
		Mode.OFFER:
			_resolve_offer(index)
		Mode.CAPACITY:
			_resolve_capacity(index)
		Mode.CAPACITY_DISCARD:
			_resolve_capacity_discard(index)
		Mode.CAPACITY_FUSE_PICK:
			_resolve_capacity_fuse_pick(index)
		Mode.FUSION_PICK_MAIN:
			_resolve_fusion_pick_main(index)
		Mode.FUSION_PICK_SUB:
			_resolve_fusion_pick_sub(index)
		Mode.FUSION_CONFIRM:
			_resolve_fusion_confirm(index)


func _on_cancel() -> void:
	match _mode:
		Mode.CAPACITY_DISCARD, Mode.CAPACITY_FUSE_PICK:
			_open_capacity_menu()
		Mode.FUSION_PICK_SUB:
			_open_fusion_pick_main()
		Mode.FUSION_CONFIRM:
			_open_fusion_pick_sub()
		_:
			_close_menu()


func _resolve_offer(index: int) -> void:
	var kind: String = String(_offer.get("kind", "none"))
	if kind == "mongju":
		var pantheons: Array = _offer.get("pantheons", []) as Array
		if index < pantheons.size():
			_finish_deal(RunState.commit_mongju(int(pantheons[index])))
		return
	if kind != "boon":
		return
	var boons_offered: Array = _offer.get("boons", []) as Array
	if index >= boons_offered.size():
		return
	var boon: BoonDef = boons_offered[index] as BoonDef
	if RunState.boon_slots_full():
		_pending_boon = boon
		_open_capacity_menu()
	else:
		_finish_deal(RunState.commit_boon(boon))


## 3칸이 찼을 때: 버리기/조합/포기 세 갈래 (7장 규칙 6). 취소로 이 메뉴를 빠져나갈 수는
## 없다. 획득 화면에서 이미 결정된 세 갈래 중 하나를 반드시 골라야 한다.
func _open_capacity_menu() -> void:
	_mode = Mode.CAPACITY
	get_tree().paused = true
	_panel.open(
		"권능 칸이 찼다: %s" % _pending_boon.display_name,
		["버리기", "조합", "포기"],
		"",
		[],
		"위아래 선택, 점프로 결정"
	)


func _resolve_capacity(index: int) -> void:
	match index:
		0:
			_open_capacity_discard()
		1:
			_open_capacity_fuse_pick()
		2:
			_finish_deal(RunState.decline_boon())


func _open_capacity_discard() -> void:
	_mode = Mode.CAPACITY_DISCARD
	get_tree().paused = true
	_panel.open(
		"버릴 권능을 고르라", _slot_labels(), "", [], "위아래 선택, 점프로 결정. ESC로 뒤로", true
	)


func _resolve_capacity_discard(index: int) -> void:
	_finish_deal(RunState.discard_and_commit_boon(index, _pending_boon))


func _open_capacity_fuse_pick() -> void:
	var labels: Array[String] = []
	var disabled: Array[bool] = []
	for i: int in range(RunState.boons.slots.size()):
		var instance: BoonInstance = RunState.boons.slots[i]
		var preview: Dictionary = RunState.fuse_in_place_preview(i, _pending_boon)
		labels.append(_fuse_candidate_label(instance, preview))
		disabled.append(not preview.get("ok", false))
	_mode = Mode.CAPACITY_FUSE_PICK
	get_tree().paused = true
	_panel.open(
		"메인으로 삼을 권능을 고르라",
		labels,
		"",
		disabled,
		"위아래 선택, 점프로 결정. ESC로 뒤로",
		true
	)


func _resolve_capacity_fuse_pick(index: int) -> void:
	var outcome: Dictionary = RunState.fuse_in_place(index, _pending_boon, _next_seed())
	_finish_deal(_fusion_result_message(outcome))


## 자유 조합 메뉴 (shrine_fuse 키). 3칸이 차 있지 않아도, 신당 안이면 언제든 연다.
func _try_open_fusion_menu() -> void:
	if _mode != Mode.IDLE:
		return
	var total: int = RunState.boons.slot_count() + (1 if RunState.boons.has_active() else 0)
	if total < 2:
		_set_notice("조합할 것이 없다")
		return
	_open_fusion_pick_main()


func _open_fusion_pick_main() -> void:
	var refs: Array[int] = _all_refs()
	var labels: Array[String] = []
	var disabled: Array[bool] = []
	for ref: int in refs:
		labels.append(_instance_label(_instance_for_ref(ref), ref == -1))
		disabled.append(not _has_valid_sub(ref))
	if not disabled.has(false):
		_set_notice("조합할 상대가 없다")
		_mode = Mode.IDLE
		get_tree().paused = false
		return
	_mode = Mode.FUSION_PICK_MAIN
	_fusion_main_refs = refs
	get_tree().paused = true
	_panel.open(
		"메인으로 삼을 권능을 고르라",
		labels,
		"",
		disabled,
		"위아래 선택, 점프로 결정. ESC로 취소",
		true
	)


func _resolve_fusion_pick_main(index: int) -> void:
	if index >= _fusion_main_refs.size():
		return
	_fusion_main_ref = _fusion_main_refs[index]
	_open_fusion_pick_sub()


## 서브 후보에서 액티브(-1)는 뺀다. 액티브는 항상 메인이고 권능이 서브다 (5장 액티브 조합).
func _open_fusion_pick_sub() -> void:
	var refs: Array[int] = _all_refs().filter(
		func(r: int) -> bool: return r != _fusion_main_ref and r != -1
	)
	var labels: Array[String] = []
	var disabled: Array[bool] = []
	for ref: int in refs:
		var preview: Dictionary = RunState.fusion_preview(_fusion_main_ref, ref)
		labels.append(_instance_label(_instance_for_ref(ref), ref == -1))
		disabled.append(not preview.get("ok", false))
	if not disabled.has(false):
		_set_notice("조합할 상대가 없다")
		_close_menu()
		return
	_mode = Mode.FUSION_PICK_SUB
	_fusion_sub_refs = refs
	get_tree().paused = true
	_panel.open(
		"서브로 삼을 권능을 고르라",
		labels,
		"",
		disabled,
		"위아래 선택, 점프로 결정. ESC로 뒤로",
		true
	)


func _resolve_fusion_pick_sub(index: int) -> void:
	if index >= _fusion_sub_refs.size():
		return
	var sub_ref: int = _fusion_sub_refs[index]
	var preview: Dictionary = RunState.fusion_preview(_fusion_main_ref, sub_ref)
	if not preview.get("ok", false):
		return
	_fusion_sub_ref = sub_ref
	_open_fusion_confirm(preview)


func _open_fusion_confirm(preview: Dictionary) -> void:
	_mode = Mode.FUSION_CONFIRM
	var success_pct: float = float(preview.get("success_chance", 0.0)) * 100.0
	var great_pct: float = float(preview.get("great_chance", 0.0)) * 100.0
	get_tree().paused = true
	_panel.open(
		"이대로 조합할까",
		["조합한다", "취소"],
		"성공 %.0f%%, 대성공 %.0f%%" % [success_pct, great_pct],
		[],
		"위아래 선택, 점프로 결정. ESC로 뒤로",
		true
	)


func _resolve_fusion_confirm(index: int) -> void:
	if index == 0:
		var outcome: Dictionary = RunState.commit_fusion(_fusion_main_ref, _fusion_sub_ref, _next_seed())
		_finish_deal(_fusion_result_message(outcome))
	else:
		_close_menu()


## 신당 거래(선택, 3칸 처리, 조합)가 확정됐을 때 공통 마무리. 게임을 풀고 응답 연출을
## 튕긴다 (art_src/requests/022 E-2-3, "선택 확정 후 광량 응답").
## 이름이 _finish가 아닌 이유: 부모 Room._finish()가 전투 클리어(cleared 방출) 전용이라
## 시그니처가 다른 동명 재정의는 파싱 단계에서 거부된다. 신당 거래 마무리는 별개 개념이다.
func _finish_deal(message: String) -> void:
	get_tree().paused = false
	_set_notice(message)
	_pulse_response_lights()
	_mode = Mode.IDLE
	_pending_boon = null
	_fusion_main_ref = -2
	_fusion_sub_ref = -2


## 확정 없이 메뉴만 닫을 때 (취소, 조합 상대 없음). 응답 연출은 튕기지 않는다.
func _close_menu() -> void:
	get_tree().paused = false
	_mode = Mode.IDLE
	_pending_boon = null
	_fusion_main_ref = -2
	_fusion_sub_ref = -2


## 신이 답했다는 신호. lantern_light.gd의 _base_energy를 튕겨 올렸다 되돌린다.
## 사당은 촛불(CandleTealL/R), 서낭당은 달빛(MoonShaft)만 존재하므로 씬마다
## 있는 노드만 반응한다.
func _pulse_response_lights() -> void:
	if _candle_l != null:
		_candle_l.pulse(0.55)
	if _candle_r != null:
		_candle_r.pulse(0.55)
	if _moon_shaft != null:
		_moon_shaft.pulse(0.48)


func _fusion_result_message(outcome: Dictionary) -> String:
	if not outcome.get("ok", false):
		return "조합 불가: %s" % String(outcome.get("reason", ""))
	var instance: BoonInstance = outcome.get("instance", null) as BoonInstance
	var display_name: String = instance.display_name if instance != null else "?"
	var grade: String = "대성공" if outcome.get("great", false) else "성공"
	return "조합 %s: %s" % [grade, display_name]


func _slot_labels() -> Array[String]:
	var labels: Array[String] = []
	for instance: BoonInstance in RunState.boons.slots:
		labels.append(_instance_label(instance, false))
	return labels


func _fuse_candidate_label(instance: BoonInstance, preview: Dictionary) -> String:
	var base: String = _instance_label(instance, false)
	if not preview.get("ok", false):
		return "%s - 조합 불가" % base
	var success_pct: float = float(preview.get("success_chance", 0.0)) * 100.0
	var great_pct: float = float(preview.get("great_chance", 0.0)) * 100.0
	return "%s 성공 %.0f%% 대성공 %.0f%%" % [base, success_pct, great_pct]


func _instance_label(instance: BoonInstance, is_active: bool) -> String:
	if instance == null:
		return "-"
	var tag: String = "액티브" if is_active else "권능"
	return "%s %s (%s T%d)" % [tag, instance.display_name, instance.pantheon_name(), instance.tier]


func _instance_for_ref(ref: int) -> BoonInstance:
	if ref == -1:
		return RunState.boons.active
	if ref >= 0 and ref < RunState.boons.slots.size():
		return RunState.boons.slots[ref]
	return null


func _all_refs() -> Array[int]:
	var refs: Array[int] = []
	if RunState.boons.has_active():
		refs.append(-1)
	for i: int in range(RunState.boons.slots.size()):
		refs.append(i)
	return refs


func _has_valid_sub(main_ref: int) -> bool:
	for ref: int in _all_refs():
		if ref == main_ref or ref == -1:
			continue
		if RunState.fusion_preview(main_ref, ref).get("ok", false):
			return true
	return false


func _set_notice(text: String) -> void:
	if _notice != null:
		_notice.text = text


func _next_seed() -> int:
	_seed_counter += 1
	return int(Time.get_ticks_msec()) + _seed_counter


func _label_array(source: Array) -> Array[String]:
	var labels: Array[String] = []
	for item: Variant in source:
		labels.append(String(item))
	return labels
