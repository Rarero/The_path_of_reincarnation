extends Node

## 런 스코프 상태 (오토로드: RunState).
##
## 소멸 대상(유물, 권능과 액티브, 노잣돈, 무당 방울)을 보관한다. 사망 또는 완주 시
## reset_run으로 초기화한다.
## 유지 대상(여의주 조각, 해금)은 GameState가 보관한다 (docs/GDD.md 4장 죽음 루프).
## 효과는 직접 실행하지 않고 훅별 질의 API로만 제공한다 (docs/systems/RELICS.md 8.3, BOONS.md 9.4).

## 노잣돈 변화. amount
signal coins_changed(amount: int)
## 유물 목록 변화
signal relics_changed
## 권능 보유 변화
signal boons_changed
## 무당 방울 변화. amount (docs/systems/BOONS.md 7장 재추첨)
signal bells_changed(amount: int)

## 런 스코프 보너스가 바뀌었다 (쉼터 강화 등). 플레이어가 최대 체력을 다시 계산한다
signal run_bonuses_changed

## M2 유물 6종 (docs/systems/RELICS.md 6.1 제작 배분)
const RELIC_PATHS: Array[String] = [
	"res://resources/relics/act1/relic_bangmangi_souvenir.tres",
	"res://resources/relics/act1/relic_hazel.tres",
	"res://resources/relics/act1/relic_notdaeya.tres",
	"res://resources/relics/act1/relic_lantern_wick.tres",
	"res://resources/relics/act1/relic_pat.tres",
	"res://resources/relics/act1/relic_dogtag.tres",
]

## M2 우선 2계열(산신, 조왕)의 1티어 권능과 2/3티어 조합 결과 (docs/systems/BOONS.md 8장, 9.3)
const BOON_PATHS: Array[String] = [
	"res://resources/boons/sansin/boon_sansin_san_ppyeo.tres",
	"res://resources/boons/sansin/boon_sansin_beom_ippal.tres",
	"res://resources/boons/sansin/boon_sansin_bawi_chigi.tres",
	"res://resources/boons/jowang/boon_jowang_agungi.tres",
	"res://resources/boons/jowang/boon_jowang_janbul.tres",
	"res://resources/boons/jowang/boon_jowang_bulti.tres",
	"res://resources/boons/jowang/boon_jowang_bujikkaengi.tres",
	"res://resources/boons/sansin/boon_sansin_sanullim.tres",
	"res://resources/boons/jowang/boon_jowang_ingeolbul.tres",
	"res://resources/boons/sansin/boon_sansin_ingeoljumeok.tres",
	"res://resources/boons/jowang/boon_jowang_sanbul.tres",
	"res://resources/boons/sansin/boon_sansin_sangun_gangnim.tres",
	"res://resources/boons/jowang/boon_jowang_hwatbul_sanyang.tres",
]

## FusionRule 16종 (9.3 M2 표: 2티어 4 + 3티어 4 + 액티브 8)
const FUSION_RULE_PATHS: Array[String] = [
	"res://resources/boons/fusion/fusion_t2_sansin_sansin.tres",
	"res://resources/boons/fusion/fusion_t2_jowang_jowang.tres",
	"res://resources/boons/fusion/fusion_t2_sansin_jowang.tres",
	"res://resources/boons/fusion/fusion_t2_jowang_sansin.tres",
	"res://resources/boons/fusion/fusion_t3_sansin_sansin.tres",
	"res://resources/boons/fusion/fusion_t3_jowang_jowang.tres",
	"res://resources/boons/fusion/fusion_t3_sansin_jowang.tres",
	"res://resources/boons/fusion/fusion_t3_jowang_sansin.tres",
	"res://resources/boons/fusion/fusion_active_sansin_t1_sansin.tres",
	"res://resources/boons/fusion/fusion_active_sansin_t1_jowang.tres",
	"res://resources/boons/fusion/fusion_active_sansin_t2_sansin.tres",
	"res://resources/boons/fusion/fusion_active_sansin_t2_jowang.tres",
	"res://resources/boons/fusion/fusion_active_jowang_t1_jowang.tres",
	"res://resources/boons/fusion/fusion_active_jowang_t1_sansin.tres",
	"res://resources/boons/fusion/fusion_active_jowang_t2_jowang.tres",
	"res://resources/boons/fusion/fusion_active_jowang_t2_sansin.tres",
]

## 3티어 부가 오버레이 (9.4, M2는 TIER3_ADDON만 쓴다)
const OVERLAY_PATHS: Array[String] = [
	"res://resources/boons/overlay/overlay_sansin_t3.tres",
	"res://resources/boons/overlay/overlay_jowang_t3.tres",
]

const RARITY_TABLE_PATH: String = "res://resources/boons/tables/rarity_table.tres"
const SYNERGY_TABLE_PATH: String = "res://resources/boons/tables/synergy_table.tres"

## 신당당 재추첨 1회 제한 (7장)
const REROLL_COST_BELLS: int = 1

## 전투 드랍으로 떨이 유물이 나올 확률
@export var drop_chance: float = 0.25

var coins: int = 0
## 재추첨 소비 아이템 "무당 방울" 보유 수 (7장, 가칭). 획득처는 M2 경제 밸런싱에서
## 확정한다. 지금은 디버그 지급만 있다 (run_stage.gd 디버그 키)
var divination_bells: int = 0
## 쉼터 강화로 올린 최대 체력. 런 스코프라 사망 시 함께 사라진다
var rest_max_health: int = 0
var relics: RelicInventory = RelicInventory.new()
var boons: BoonLoadout = BoonLoadout.new()

var _relic_pool: Array[RelicDef] = []
var _boon_pool: Array[BoonDef] = []
var _boon_by_id: Dictionary = {}
var _fusion_rules: Array[FusionRule] = []
var _overlay_by_id: Dictionary = {}
var _rarity_table: RarityTable = null
var _synergy_table: SynergyTable = null
var _run_active: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## 액티브 권능이 건 일시 강화. key -> {value, left}
var _temp_mults: Dictionary = {}
var _temp_flats: Dictionary = {}


func _ready() -> void:
	_rng.randomize()
	_load_pools()
	boons.rarity_table = _rarity_table
	boons.synergy_table = _synergy_table


## 새 런 시작. 소멸 상태를 비운다.
func begin_run() -> void:
	reset_run()
	_run_active = true


## 런 종료(사망 또는 완주). 소멸 대상을 초기화한다. 여의주와 해금은 GameState라 남는다.
func reset_run() -> void:
	coins = 0
	divination_bells = 0
	rest_max_health = 0
	relics.clear()
	boons.clear()
	_temp_mults.clear()
	_temp_flats.clear()
	_run_active = false
	coins_changed.emit(coins)
	bells_changed.emit(divination_bells)
	relics_changed.emit()
	boons_changed.emit()


func is_run_active() -> bool:
	return _run_active


## 중단 저장용 직렬화. 리소스 참조가 아니라 id 문자열로 저장한다 (docs/DECISIONS.md 2026-08-04).
## 권능 인스턴스는 등급과 티어와 덤과 각인을 함께 저장한다 (9.8).
## 유물 충전 잔량은 저장하지 않는다. 재개 시 방 시작 단위라 충전은 초기값으로 재무장한다
func to_save() -> Dictionary:
	var relic_ids: Array = []
	for def: RelicDef in relics.all():
		relic_ids.append(String(def.id))
	var slot_data: Array = []
	for instance: BoonInstance in boons.slots:
		slot_data.append(_instance_to_save(instance))
	var active_data: Dictionary = _instance_to_save(boons.active) if boons.has_active() else {}
	return {
		"coins": coins,
		"bells": divination_bells,
		"rest_hp": rest_max_health,
		"relics": relic_ids,
		"mongju": boons.mongju,
		"active": active_data,
		"slots": slot_data,
	}


func _instance_to_save(instance: BoonInstance) -> Dictionary:
	if instance == null or instance.def == null:
		return {}
	return {
		"id": String(instance.id),
		"tier": instance.tier,
		"rarity": instance.rarity,
		"rarity_bonus": instance.rarity_bonus,
		"mark_pantheon": instance.mark_pantheon,
	}


## 중단 저장에서 런 상태를 복원한다. 재개 시 씬(플레이어) 로드 전에 호출해야 최대 체력 보정이 반영된다.
func load_save(data: Dictionary) -> void:
	reset_run()
	coins = int(data.get("coins", 0))
	divination_bells = int(data.get("bells", 0))
	rest_max_health = int(data.get("rest_hp", 0))
	for id_value: Variant in data.get("relics", []):
		grant_relic_by_id(StringName(id_value))
	var active_data: Dictionary = data.get("active", {}) as Dictionary
	if not active_data.is_empty():
		var active_instance: BoonInstance = _instance_from_save(active_data)
		if active_instance != null:
			boons.set_active_instance(active_instance)
	for slot_value: Variant in data.get("slots", []):
		var instance: BoonInstance = _instance_from_save(slot_value as Dictionary)
		if instance != null:
			boons.add_instance(instance)
	_run_active = true
	coins_changed.emit(coins)
	bells_changed.emit(divination_bells)
	relics_changed.emit()
	boons_changed.emit()


func _instance_from_save(data: Dictionary) -> BoonInstance:
	if data.is_empty():
		return null
	var def: BoonDef = _boon_by_id.get(StringName(data.get("id", "")), null)
	if def == null:
		return null
	var instance: BoonInstance = BoonInstance.new(def)
	instance.tier = int(data.get("tier", def.tier))
	instance.rarity = int(data.get("rarity", BoonDef.Rarity.SEUCHIM))
	instance.rarity_bonus = float(data.get("rarity_bonus", 0.0))
	instance.mark_pantheon = int(data.get("mark_pantheon", -1))
	return instance


## 재개 시 상태를 비우지 않고 런만 활성화한다 (load_save가 이미 상태를 채운 경우).
func resume_run() -> void:
	_run_active = true


## 적 처치 통지. 노잣돈을 더하고 전투 드랍을 굴린다. 런 중에만 누적한다.
func notify_kill(coin_reward: int) -> void:
	if not _run_active:
		return
	add_coins(coin_reward)
	if _rng.randf() <= drop_chance:
		_roll_drop_relic()


func add_coins(amount: int) -> void:
	if amount == 0:
		return
	coins = maxi(0, coins + amount)
	coins_changed.emit(coins)


## 무당 방울을 더한다 (디버그 지급, 후속 경제 밸런싱에서 정식 획득처로 대체).
func add_bells(amount: int) -> void:
	if amount == 0:
		return
	divination_bells = maxi(0, divination_bells + amount)
	bells_changed.emit(divination_bells)


## id로 유물을 지급한다 (디버그, 보상). 성공하면 true.
func grant_relic_by_id(id: StringName) -> bool:
	var def: RelicDef = _relic_by_id(id)
	if def == null:
		return false
	if relics.add(def):
		relics_changed.emit()
		return true
	return false


## 그 등급과 획득처의 1막 유물 하나를 무작위로 준다 (전투 드랍, 이벤트 보상).
## 이미 가진 것은 후보에서 빠진다. 준 유물을 돌려주고, 줄 것이 없으면 null.
func grant_random_relic(grade: int, source: StringName) -> RelicDef:
	var candidates: Array[RelicDef] = []
	for def: RelicDef in _relic_pool:
		if def.grade != grade or not def.sources.has(source):
			continue
		if def.act_pool.has(1) and not relics.has(def.id):
			candidates.append(def)
	if candidates.is_empty():
		return null
	var pick: RelicDef = candidates[_rng.randi_range(0, candidates.size() - 1)]
	if not relics.add(pick):
		return null
	relics_changed.emit()
	return pick


## 보스 보상용 권능 즉시 지급. 몸주 계열 후보가 있으면 그쪽에서 고르고, 없으면 전체에서
## 고른다. 3칸이 찼거나 후보가 없으면 조용히 건너뛴다.
##
## 신당 3택과 다른 경로다. 보스 사망 연출 중에 선택 UI를 띄우지 않기 위해 즉시 지급이며,
## 추첨은 바로 위 grant_random_relic과 같은 _rng를 쓴다 (docs/act1/BOSS.md 보상).
func grant_random_boon(pantheon: int) -> BoonDef:
	if boon_slots_full():
		return null
	var candidates: Array[BoonDef] = _shrine_candidates()
	if candidates.is_empty():
		return null
	var same_pantheon: Array[BoonDef] = []
	for def: BoonDef in candidates:
		if int(def.pantheon) == pantheon:
			same_pantheon.append(def)
	var pool: Array[BoonDef] = candidates if same_pantheon.is_empty() else same_pantheon
	var pick: BoonDef = pool[_rng.randi_range(0, pool.size() - 1)]
	if not boons.add_boon(pick):
		return null
	boons_changed.emit()
	return pick


## 유물과 권능을 합친 가산 스탯 보너스.
func total_stat_flat(key: StringName) -> float:
	var rest: float = float(rest_max_health) if key == &"max_health" else 0.0
	return (
		relics.flat_bonus(key) + boons.flat_bonus(key) + _temp_bonus(_temp_flats, key) + rest
	)


## 유물과 권능을 합친 배율. 곱연산 없이 1.0 + 가산 합 (docs/systems/RELICS.md 3장).
## 액티브 권능이 건 일시 강화도 같은 가산 층에 얹는다 (범의 이빨 등).
func total_stat_mult(key: StringName) -> float:
	return (
		1.0 + relics.mult_bonus(key) + boons.mult_bonus(key) + _temp_bonus(_temp_mults, key)
	)


## 일시 강화를 건다. 같은 키에 다시 걸면 값과 남은 시간 모두 큰 쪽이 남는다.
## 액티브 권능처럼 짧게 걸렸다 사라지는 효과 전용이며, 지속 효과는 .tres에 둔다.
func grant_temp_mult(key: StringName, value: float, duration: float) -> void:
	_grant_temp(_temp_mults, key, value, duration)


func grant_temp_flat(key: StringName, value: float, duration: float) -> void:
	_grant_temp(_temp_flats, key, value, duration)


func _grant_temp(store: Dictionary, key: StringName, value: float, duration: float) -> void:
	if duration <= 0.0 or is_zero_approx(value):
		return
	var entry: Dictionary = store.get(key, {}) as Dictionary
	store[key] = {
		"value": maxf(float(entry.get("value", 0.0)), value),
		"left": maxf(float(entry.get("left", 0.0)), duration),
	}


func _temp_bonus(store: Dictionary, key: StringName) -> float:
	var entry: Dictionary = store.get(key, {}) as Dictionary
	return float(entry.get("value", 0.0))


## 일시 강화의 남은 시간을 줄인다. 실시간이라 _process에서 돈다.
func _tick_temp(store: Dictionary, delta: float) -> void:
	if store.is_empty():
		return
	var expired: Array[StringName] = []
	for key: StringName in store:
		var entry: Dictionary = store[key] as Dictionary
		var left: float = float(entry["left"]) - delta
		if left <= 0.0:
			expired.append(key)
		else:
			entry["left"] = left
	for key: StringName in expired:
		store.erase(key)


func _process(delta: float) -> void:
	_tick_temp(_temp_mults, delta)
	_tick_temp(_temp_flats, delta)


## 시스템 규칙 질의. 기본값에 유물 규칙 개조분을 더한다 (예: 데스매치 지연).
func relic_rule(key: StringName, default_value: float) -> float:
	return default_value + relics.rule_bonus(key)


## 치명 피해를 무효화할 유물 충전이 있으면 소비하고 true (군번줄). Health가 질의한다.
func try_absorb_lethal() -> bool:
	return relics.try_absorb_lethal()


## 쉼터 통과 시 유물 충전을 되돌린다.
## 쉼터 강화. 최대 체력을 올리고 플레이어에게 재계산을 알린다.
## 플레이어는 잃은 양을 유지한 채 최대치만 올리므로 오른 만큼이 곧 회복이 된다
func add_rest_max_health(amount: int) -> void:
	if amount <= 0:
		return
	rest_max_health += amount
	run_bonuses_changed.emit()


func notify_rest() -> void:
	relics.recharge_at_rest()


## 피격 시 경직 유물(개암 한 알)이 준비됐으면 true. 플레이어가 주변 적 경직에 쓴다.
func consume_hit_taken_stagger() -> bool:
	return relics.hit_taken_ready(_now())


## 신당 3택을 굴린다(부여하지 않음). kind: mongju/boon/none와 options, labels를 담는다.
## 첫 신당은 몸주 계열 3택, 이후 신당은 권능 3택이다. 선택 확정은 commit_mongju/commit_boon.
func roll_shrine(offer_seed: int) -> Dictionary:
	if not boons.has_active():
		var pantheons: Array[int] = ShrineOffer.offer_mongju(_active_pantheons(), offer_seed, 3)
		if pantheons.is_empty():
			return {"kind": "none"}
		var mongju_labels: Array[String] = []
		for pantheon: int in pantheons:
			mongju_labels.append(String(BoonDef.PANTHEON_NAMES.get(pantheon, "")))
		return {"kind": "mongju", "pantheons": pantheons, "labels": mongju_labels}
	var offered: Array[BoonDef] = ShrineOffer.offer(
		_shrine_candidates(), boons.mongju, offer_seed, 3
	)
	if offered.is_empty():
		return {"kind": "none"}
	var boon_labels: Array[String] = []
	for def: BoonDef in offered:
		boon_labels.append(boon_label_for(def))
	return {"kind": "boon", "boons": offered, "labels": boon_labels}


## 신당 3택과 목록에 쓰는 한 줄 설명. 이름과 계열만으로는 무엇을 고르는지 알 수 없으므로
## description을 함께 보여준다 (BOONS 7장 3택 비교는 계열과 효과로 이루어진다).
func boon_label_for(def: BoonDef) -> String:
	if def == null:
		return ""
	var head: String = "%s (%s)" % [def.display_name, def.pantheon_name()]
	if def.description.is_empty():
		return head
	return "%s\n    %s" % [head, def.description]


## 재추첨 가능 여부. 몸주 신당(액티브 없음)에는 재추첨이 없다 (7장, 규칙 37).
func can_reroll_shrine() -> bool:
	return boons.has_active() and divination_bells >= REROLL_COST_BELLS


## 재추첨. 무당 방울 1개를 쓰고 권능 3택을 새 시드로 다시 뽑는다. 신당당 1회 제한은
## 호출자(room_shrine.gd)가 자기 방문 상태로 지킨다 (규칙 37).
func reroll_shrine(offer_seed: int) -> Dictionary:
	if not can_reroll_shrine():
		return {"kind": "none"}
	# 먼저 굴려 보고 담을 것이 있을 때만 방울을 쓴다. 후보가 소진된 신당에서
	# 방울만 사라지는 경로를 만들지 않는다
	var offer: Dictionary = roll_shrine(offer_seed)
	if String(offer.get("kind", "none")) == "none":
		return offer
	divination_bells -= REROLL_COST_BELLS
	bells_changed.emit(divination_bells)
	return offer


## 몸주 선택 확정. 몸주 계열의 액티브를 부여한다. 결과 메시지를 돌려준다.
func commit_mongju(pantheon: int) -> String:
	var active_def: BoonDef = _active_of(pantheon)
	if active_def == null:
		return "신당: 액티브 없음"
	boons.set_active(active_def)
	boons_changed.emit()
	return (
		"몸주 %s. 액티브 %s"
		% [String(BoonDef.PANTHEON_NAMES.get(pantheon, "")), active_def.display_name]
	)


## 권능 선택 확정. 3칸이 찼으면 호출하지 마라 (boon_slots_full로 먼저 분기, 7장).
func commit_boon(boon: BoonDef) -> String:
	if boon == null:
		return "신당: 선택 없음"
	if not boons.add_boon(boon):
		return "신당: 담을 수 없다"
	boons_changed.emit()
	return "권능 획득 %s" % boon.display_name


## 3칸이 찼을 때: 지정한 슬롯을 버리고 새 권능을 담는다 (7장 3칸 처리).
func discard_and_commit_boon(slot_index: int, boon: BoonDef) -> String:
	if boon == null:
		return "신당: 선택 없음"
	var dropped: BoonInstance = boons.remove_slot(slot_index)
	if not boons.add_boon(boon):
		if dropped != null:
			boons.insert_instance(slot_index, dropped)
		return "신당: 실패"
	# 버린 자리에 그대로 넣는다. 끝에 붙이면 고른 자리와 결과가 어긋나 보인다
	var placed: BoonInstance = boons.remove_slot(boons.slot_count() - 1)
	if placed != null:
		boons.insert_instance(slot_index, placed)
	boons_changed.emit()
	var dropped_name: String = dropped.display_name if dropped != null else "?"
	return "%s 을(를) 버리고 %s 획득" % [dropped_name, boon.display_name]


## 3칸이 찼을 때: 획득을 포기한다.
func decline_boon() -> String:
	return "신당: 획득 포기"


## 3칸이 찼을 때 그 자리 조합의 미리보기 (확률 공개용, 5장). 아무것도 소모하지 않는다.
func fuse_in_place_preview(slot_index: int, incoming: BoonDef) -> Dictionary:
	if slot_index < 0 or slot_index >= boons.slots.size() or incoming == null:
		return {"ok": false, "reason": "invalid"}
	var main_instance: BoonInstance = boons.slots[slot_index]
	var sub_instance: BoonInstance = BoonInstance.new(incoming)
	var preview: Dictionary = BoonFusion.preview(
		main_instance, sub_instance, false, _fusion_rules, _relic_fusion_great_bonus()
	)
	if not preview.get("ok", false):
		return preview
	# 서브는 아직 손에 없는 새 권능이라 소모되는 칸은 메인 하나뿐이다
	var consumed: Array[int] = [slot_index]
	if _result_id_blocked(preview.get("rule", null) as FusionRule, consumed):
		return {"ok": false, "reason": "duplicate_result"}
	return preview


## 3칸이 찼을 때: 기존 슬롯 하나를 메인, 새로 받은 권능을 서브로 그 자리에서 조합한다.
func fuse_in_place(slot_index: int, incoming: BoonDef, roll_seed: int) -> Dictionary:
	var checked: Dictionary = fuse_in_place_preview(slot_index, incoming)
	if not checked.get("ok", false):
		return checked
	var main_instance: BoonInstance = boons.slots[slot_index]
	var sub_instance: BoonInstance = BoonInstance.new(incoming)
	var outcome: Dictionary = BoonFusion.resolve(
		main_instance,
		sub_instance,
		false,
		_fusion_rules,
		_boon_by_id,
		_overlay_by_id,
		_rarity_table,
		roll_seed,
		_relic_fusion_great_bonus()
	)
	if not outcome.get("ok", false):
		return outcome
	var removed: BoonInstance = boons.remove_slot(slot_index)
	if not boons.add_instance(outcome["instance"] as BoonInstance):
		if removed != null:
			boons.add_instance(removed)
		return {"ok": false, "reason": "cannot_place"}
	boons_changed.emit()
	return outcome


## 조합 미리보기 (확률 공개용, 5장). main_ref/sub_ref: -1은 액티브, 0~2는 권능 슬롯.
## 액티브는 서브가 될 수 없다 (5장: 액티브가 항상 메인이고 권능이 서브다).
func fusion_preview(main_ref: int, sub_ref: int) -> Dictionary:
	if main_ref == sub_ref:
		return {"ok": false, "reason": "same_slot"}
	if sub_ref == -1:
		return {"ok": false, "reason": "active_as_sub"}
	var main_instance: BoonInstance = _instance_at(main_ref)
	var sub_instance: BoonInstance = _instance_at(sub_ref)
	var is_active: bool = main_ref == -1
	var preview: Dictionary = BoonFusion.preview(
		main_instance, sub_instance, is_active, _fusion_rules, _relic_fusion_great_bonus()
	)
	if not preview.get("ok", false):
		return preview
	# 삼항 연산자에 배열 리터럴을 쓰면 타입 배열 추론이 흔들린다. 명시적으로 만든다
	var consumed: Array[int] = []
	consumed.append(sub_ref)
	if not is_active:
		consumed.append(main_ref)
	if _result_id_blocked(preview.get("rule", null) as FusionRule, consumed):
		return {"ok": false, "reason": "duplicate_result"}
	return preview


## 조합 결과와 같은 id를 재료가 아닌 다른 칸이 이미 들고 있으면 결과를 담을 수 없다
## (BoonLoadout이 중복 id를 거부한다). 재료를 태우고 결과를 잃는 경로를 막기 위해
## 미리보기 단계에서 걸러 UI가 그 선택지를 비활성으로 표시하게 한다.
func _result_id_blocked(rule: FusionRule, consumed_slots: Array[int]) -> bool:
	if rule == null or String(rule.result_id).is_empty():
		return false
	for i: int in range(boons.slots.size()):
		if consumed_slots.has(i):
			continue
		if boons.slots[i].id == rule.result_id:
			return true
	return false


## 조합 실행. main_ref가 메인이 되고, 성공하면 서브가 소모된다.
func commit_fusion(main_ref: int, sub_ref: int, roll_seed: int) -> Dictionary:
	var checked: Dictionary = fusion_preview(main_ref, sub_ref)
	if not checked.get("ok", false):
		return checked
	var main_instance: BoonInstance = _instance_at(main_ref)
	var sub_instance: BoonInstance = _instance_at(sub_ref)
	var is_active: bool = main_ref == -1
	var outcome: Dictionary = BoonFusion.resolve(
		main_instance,
		sub_instance,
		is_active,
		_fusion_rules,
		_boon_by_id,
		_overlay_by_id,
		_rarity_table,
		roll_seed,
		_relic_fusion_great_bonus()
	)
	if not outcome.get("ok", false):
		return outcome
	var result_instance: BoonInstance = outcome["instance"] as BoonInstance
	if is_active:
		boons.remove_slot(sub_ref)  ## 액티브는 main_instance를 그대로 강화(같은 인스턴스)한다
	else:
		# 큰 인덱스를 먼저 뺀다. 그래야 남은 인덱스가 밀리지 않는다
		var high: int = maxi(main_ref, sub_ref)
		var low: int = mini(main_ref, sub_ref)
		var removed_high: BoonInstance = boons.remove_slot(high)
		var removed_low: BoonInstance = boons.remove_slot(low)
		if not boons.add_instance(result_instance):
			# 재료만 태우고 결과를 잃는 경로를 만들지 않는다. 미리보기가 이미 걸러내지만
			# 안전망으로 되돌린다
			if removed_low != null:
				boons.add_instance(removed_low)
			if removed_high != null:
				boons.add_instance(removed_high)
			return {"ok": false, "reason": "cannot_place"}
	boons_changed.emit()
	return outcome


## 3칸이 찼는지 여부. 신당의 3칸 처리 분기에 쓴다 (7장).
func boon_slots_full() -> bool:
	return boons.is_full()


## HUD용 유물 요약 문자열.
func relic_display() -> String:
	var owned: Array[RelicDef] = relics.all()
	if owned.is_empty():
		return "유물 없음"
	var names: PackedStringArray = PackedStringArray()
	for def: RelicDef in owned:
		names.append(def.display_name)
	return "유물 %s" % ", ".join(names)


## HUD용 권능 요약 문자열 (몸주와 권능 슬롯).
func boon_display() -> String:
	var mongju_text: String = "몸주 -"
	if boons.has_active():
		mongju_text = "몸주 %s" % boons.active.pantheon_name()
	var slot_names: PackedStringArray = PackedStringArray()
	for instance: BoonInstance in boons.slots:
		slot_names.append(instance.display_name)
	var slots_text: String = ", ".join(slot_names) if slot_names.size() > 0 else "-"
	return "%s | 권능 %s" % [mongju_text, slots_text]


func _load_pools() -> void:
	for path: String in RELIC_PATHS:
		var def: RelicDef = load(path) as RelicDef
		if def != null:
			_relic_pool.append(def)
		else:
			push_warning("유물 리소스 로드 실패: %s" % path)
	for path: String in BOON_PATHS:
		var boon: BoonDef = load(path) as BoonDef
		if boon != null:
			_boon_pool.append(boon)
			_boon_by_id[boon.id] = boon
		else:
			push_warning("권능 리소스 로드 실패: %s" % path)
	for path: String in FUSION_RULE_PATHS:
		var rule: FusionRule = load(path) as FusionRule
		if rule != null:
			_fusion_rules.append(rule)
		else:
			push_warning("조합 규칙 로드 실패: %s" % path)
	for path: String in OVERLAY_PATHS:
		var overlay: PantheonOverlay = load(path) as PantheonOverlay
		if overlay != null:
			_overlay_by_id[overlay.id] = overlay
		else:
			push_warning("오버레이 로드 실패: %s" % path)
	_rarity_table = load(RARITY_TABLE_PATH) as RarityTable
	_synergy_table = load(SYNERGY_TABLE_PATH) as SynergyTable


func _roll_drop_relic() -> void:
	grant_random_relic(RelicDef.Grade.TTEORI, &"drop")


func _relic_by_id(id: StringName) -> RelicDef:
	for def: RelicDef in _relic_pool:
		if def.id == id:
			return def
	return null


## id로 권능 정의를 찾는다. 없으면 null. 보상 지급과 테스트에서 쓴다.
func boon_def(id: StringName) -> BoonDef:
	return _boon_by_id.get(id, null)


## 구현된 액티브가 있는 상시 계열 목록.
func _active_pantheons() -> Array[int]:
	var result: Array[int] = []
	for def: BoonDef in _boon_pool:
		if def.kind != BoonDef.Kind.ACTIVE or not def.implemented:
			continue
		if def.layer != BoonDef.Layer.REGULAR:
			continue
		if not result.has(int(def.pantheon)):
			result.append(int(def.pantheon))
	return result


## 그 계열의 액티브형 권능 1종을 돌려준다. 산신처럼 액티브가 여럿이면 풀 순서상 첫
## 번째를 결정적으로 고른다. 3종 중 세부 선택 UI는 M2 범위 밖이다 (12장).
func _active_of(pantheon: int) -> BoonDef:
	for def: BoonDef in _boon_pool:
		if def.kind == BoonDef.Kind.ACTIVE and int(def.pantheon) == pantheon and def.implemented:
			return def
	return null


## 일반 신당 후보: 구현된 상시 1티어 NORMAL 권능 중 보유하지 않은 것. 액티브형은 여기
## 섞이지 않는다 (규칙 23).
func _shrine_candidates() -> Array[BoonDef]:
	var held: Array[StringName] = boons.held_ids()
	var result: Array[BoonDef] = []
	for def: BoonDef in _boon_pool:
		if def.kind != BoonDef.Kind.NORMAL or not def.implemented:
			continue
		if def.layer != BoonDef.Layer.REGULAR or def.tier != 1:
			continue
		if def.act_pool.has(1) and not held.has(def.id):
			result.append(def)
	return result


## -1은 액티브, 0 이상은 권능 슬롯 인덱스.
func _instance_at(ref: int) -> BoonInstance:
	if ref == -1:
		return boons.active
	if ref >= 0 and ref < boons.slots.size():
		return boons.slots[ref]
	return null


## 유물의 조합 대성공 확률 보정 (조왕 중발류, RELICS 6.2 14번). M2 유물 6종에는 아직
## 없어 항상 0.0이지만 RelicEffect.Hook.RULE_OVERRIDE 파이프라인은 이미 연결돼 있다.
func _relic_fusion_great_bonus() -> float:
	return relics.rule_bonus(&"fusion_great_chance")


func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0
