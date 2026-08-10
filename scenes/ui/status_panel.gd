class_name StatusPanel
extends CanvasLayer

## 런 상태 확인 창. I 키(게임패드 Back)로 열고 닫는다.
##
## 현재 무기, 권능(몸주와 슬롯), 유물, 재화, 주요 상태를 한 화면에서 보여준다.
## - 열려 있는 동안 get_tree().paused로 플레이를 멈춘다. process_mode는 ALWAYS라 멈춘 동안에도 동작한다
## - 일시정지 메뉴나 노드 지도가 떠 있으면 이미 paused 상태라 열리지 않는다 (중첩 방지)
## - 표시 전용이다. 이 창에서는 무엇도 바꾸지 않는다
## - 무기 2슬롯은 미구현이라 현재는 기본 총과 총검만 나온다 (docs/WORK_PLAN_M2.md G4)

## RelicDef.Grade 순서와 같다 (떨이, 물건, 진품)
const GRADE_NAMES: Array[String] = ["떨이", "물건", "진품"]
## BoonDef.Rarity 순서와 같다 (스침, 실림, 온내림, 6장)
const RARITY_NAMES: Array[String] = ["스침", "실림", "온내림"]
## 권능 아이콘 한 칸 크기 (원본 16x16)
const ICON_SIZE: Vector2 = Vector2(16, 16)
## 설명문 한 줄 최대 글자 수 (오른쪽 칸 폭 기준)
const DESCRIPTION_WRAP: int = 22
## 설명은 최대 이 줄 수까지만 보여준다. 전문은 신당 선택 화면과 아이콘 툴팁에 있다
const DESCRIPTION_MAX_LINES: int = 2

@onready var _root: Control = $Root as Control
@onready var _left_label: Label = %LeftLabel as Label
@onready var _right_label: Label = %RightLabel as Label
@onready var _coin_label: Label = %CoinLabel as Label
@onready var _boon_icons: HBoxContainer = %BoonIcons as HBoxContainer

var _health: int = 0
var _health_max: int = 0
var _stamina: float = 0.0
var _stamina_max: float = 0.0
var _ammo: int = 0
var _magazine: int = 0
var _reloading: bool = false


func _ready() -> void:
	GameEvents.player_health_changed.connect(_on_health_changed)
	GameEvents.player_stamina_changed.connect(_on_stamina_changed)
	GameEvents.player_ammo_changed.connect(_on_ammo_changed)
	_root.hide()


func _unhandled_input(event: InputEvent) -> void:
	var toggle: bool = event.is_action_pressed(&"inventory")
	var cancel: bool = event.is_action_pressed(&"ui_cancel")
	if not toggle and not cancel:
		return
	if _root.visible:
		_close()
		get_viewport().set_input_as_handled()
	elif toggle and not get_tree().paused:
		_open()
		get_viewport().set_input_as_handled()


func _on_health_changed(current: int, maximum: int) -> void:
	_health = current
	_health_max = maximum


func _on_stamina_changed(current: float, maximum: float) -> void:
	_stamina = current
	_stamina_max = maximum


func _on_ammo_changed(current: int, magazine_size: int, reloading: bool) -> void:
	_ammo = current
	_magazine = magazine_size
	_reloading = reloading


func _open() -> void:
	_refresh()
	_root.show()
	get_tree().paused = true


func _close() -> void:
	_root.hide()
	get_tree().paused = false


func _refresh() -> void:
	_refresh_boon_icons()
	_left_label.text = "%s\n\n%s\n\n%s" % [_weapon_text(), _state_text(), _relic_text()]
	_right_label.text = _boon_text()
	_coin_label.text = "엽전 %d      여의주 조각 %d" % [RunState.coins, GameState.yeouiju_shards]


func _weapon_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[무기]")
	var rifle: WeaponRifle = _find_rifle()
	if rifle == null:
		lines.append("  정보 없음")
		return "\n".join(lines)
	var reload_mark: String = "  재장전 중" if _reloading else ""
	lines.append("  기본 총")
	lines.append("    탄약 %d / %d%s" % [_ammo, _magazine, reload_mark])
	lines.append("    탄 피해 %d" % rifle.bullet_damage)
	var melee_damage: int = _melee_damage(rifle)
	if melee_damage > 0:
		lines.append("  총검")
		lines.append("    피해 %d" % melee_damage)
	lines.append("  2번 슬롯  미구현")
	return "\n".join(lines)


func _state_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[상태]")
	lines.append("  체력  %d / %d" % [_health, _health_max])
	lines.append("  스태미나  %d / %d" % [int(round(_stamina)), int(round(_stamina_max))])
	lines.append("  근접 피해  x%.2f" % RunState.total_stat_mult(&"melee_damage"))
	return "\n".join(lines)


## 액티브 1칸과 권능 3칸의 아이콘 줄. 이름을 읽지 않아도 무엇을 들고 있는지 보이게 한다.
## 아이콘이 없는 정의(조합 결과 등)는 자리만 어둡게 남긴다.
func _refresh_boon_icons() -> void:
	for child: Node in _boon_icons.get_children():
		_boon_icons.remove_child(child)
		child.queue_free()
	var loadout: BoonLoadout = RunState.boons
	if loadout.has_active():
		_boon_icons.add_child(_icon_node(loadout.active, true))
	for index: int in range(BoonLoadout.MAX_SLOTS):
		if index < loadout.slots.size():
			_boon_icons.add_child(_icon_node(loadout.slots[index], false))
		else:
			_boon_icons.add_child(_empty_slot_node())


func _icon_node(instance: BoonInstance, is_active: bool) -> Control:
	var texture: Texture2D = instance.def.icon if instance != null and instance.def != null else null
	if texture == null:
		var missing: ColorRect = _empty_slot_node()
		missing.color = Color(0.34, 0.3, 0.26, 1.0)
		missing.tooltip_text = instance.display_name if instance != null else ""
		return missing
	var rect: TextureRect = TextureRect.new()
	rect.texture = texture
	rect.custom_minimum_size = ICON_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP
	rect.tooltip_text = "%s%s" % ["액티브 " if is_active else "", instance.display_name]
	return rect


func _empty_slot_node() -> ColorRect:
	var slot: ColorRect = ColorRect.new()
	slot.color = Color(0.16, 0.15, 0.14, 1.0)
	slot.custom_minimum_size = ICON_SIZE
	return slot


func _boon_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[권능]")
	var loadout: BoonLoadout = RunState.boons
	var mongju_name: String = "미정"
	if loadout.mongju >= 0:
		mongju_name = String(BoonDef.PANTHEON_NAMES.get(loadout.mongju, "미정"))
	lines.append("  몸주  %s" % mongju_name)
	if loadout.has_active():
		var active: BoonInstance = loadout.active
		lines.append(
			"  액티브  %s  T%d, %s" % [active.display_name, active.tier, _rarity_name(active.rarity)]
		)
		lines.append(_description_lines(active))
	else:
		lines.append("  액티브  -")
	for index: int in range(BoonLoadout.MAX_SLOTS):
		if index < loadout.slots.size():
			lines.append(_slot_text(index + 1, loadout.slots[index]))
		else:
			lines.append("  %d. -" % (index + 1))
	lines.append(_active_text())
	lines.append(_synergy_text(loadout))
	return "\n".join(lines)


## 액티브 발동 준비 상태. 쿨다운이 돌고 있으면 남은 초를 보여준다.
func _active_text() -> String:
	if not RunState.boons.has_active():
		return "  발동  -"
	if BoonRuntime.active_ready():
		return "  발동  준비됨 (L)"
	return "  발동  %.1f초 남음" % BoonRuntime.cooldown_left()


## 계열 시너지 요약 (8.7). 2단계 이상인 계열만 보여준다.
func _synergy_text(loadout: BoonLoadout) -> String:
	var stages: Dictionary = SynergyCalculator.stages(loadout)
	if stages.is_empty():
		return "  시너지  -"
	var parts: PackedStringArray = PackedStringArray()
	for pantheon: int in stages.keys():
		var pantheon_name: String = String(BoonDef.PANTHEON_NAMES.get(pantheon, "?"))
		parts.append("%s %d단계" % [pantheon_name, int(stages[pantheon])])
	return "  시너지  %s" % ", ".join(parts)


## 권능 한 칸의 표시. 이름과 등급 아래에 무엇을 하는 권능인지 설명을 붙인다.
## 이름만 보여주면 무엇을 골랐는지도 무엇을 고를지도 알 수 없다.
func _slot_text(number: int, instance: BoonInstance) -> String:
	var head: String = (
		"  %d. %s  %s T%d, %s"
		% [
			number,
			instance.display_name,
			instance.pantheon_name(),
			instance.tier,
			_rarity_name(instance.rarity)
		]
	)
	return "%s\n%s" % [head, _description_lines(instance)]


## 설명문을 패널 폭에 맞춰 접어 들여쓴다. Label은 자동 줄바꿈을 쓰지 않으므로 직접 나눈다.
func _description_lines(instance: BoonInstance) -> String:
	if instance == null or instance.def == null or instance.def.description.is_empty():
		return "        -"
	var words: PackedStringArray = instance.def.description.split(" ", false)
	var out: PackedStringArray = PackedStringArray()
	var line: String = ""
	for word: String in words:
		if line.is_empty():
			line = word
		elif line.length() + word.length() + 1 <= DESCRIPTION_WRAP:
			line += " " + word
		else:
			out.append("        " + line)
			line = word
	if not line.is_empty():
		out.append("        " + line)
	if out.size() > DESCRIPTION_MAX_LINES:
		out.resize(DESCRIPTION_MAX_LINES)
		out[DESCRIPTION_MAX_LINES - 1] = out[DESCRIPTION_MAX_LINES - 1] + " ..."
	return "\n".join(out)


func _rarity_name(rarity: int) -> String:
	if rarity < 0 or rarity >= RARITY_NAMES.size():
		return "?"
	return RARITY_NAMES[rarity]


func _relic_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	var owned: Array[RelicDef] = RunState.relics.all()
	lines.append("[유물]  %d개" % owned.size())
	if owned.is_empty():
		lines.append("  없음")
		return "\n".join(lines)
	for def: RelicDef in owned:
		lines.append("  %s [%s]" % [def.display_name, _grade_name(def.grade)])
	return "\n".join(lines)


func _grade_name(grade: int) -> String:
	if grade < 0 or grade >= GRADE_NAMES.size():
		return "?"
	return GRADE_NAMES[grade]


## 총검 판정 피해. Hitbox가 없으면 0을 돌려 표시를 건너뛴다
func _melee_damage(rifle: WeaponRifle) -> int:
	var hitbox: Hitbox = rifle.get_node_or_null(^"MeleeHitbox") as Hitbox
	if hitbox == null:
		return 0
	return hitbox.damage


func _find_rifle() -> WeaponRifle:
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return null
	return player.get_node_or_null(^"Rifle") as WeaponRifle
