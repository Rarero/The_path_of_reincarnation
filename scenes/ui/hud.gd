extends CanvasLayer

## HUD. 체력, 스태미나, 탄약, 생기 몰림 상태를 표시한다.
## 바 아트는 옻칠 나무 프레임 + 황동 모서리 톤(2026-08-03 적용, assets/sprites/ui/bar_*).

@onready var health_bar: TextureProgressBar = $Root/HealthBar as TextureProgressBar
@onready var stamina_bar: TextureProgressBar = $Root/StaminaBar as TextureProgressBar
@onready var ammo_label: Label = $Root/AmmoLabel as Label
@onready var rage_label: Label = $Root/RageLabel as Label
@onready var room_label: Label = $Root/RoomLabel as Label
@onready var run_label: Label = $Root/RunLabel as Label
@onready var relic_label: Label = $Root/RelicLabel as Label
@onready var boon_label: Label = $Root/BoonLabel as Label
@onready var boss_panel: Control = $Root/BossPanel as Control
@onready var boss_bar: TextureProgressBar = $Root/BossPanel/BossBar as TextureProgressBar
@onready var boss_name_label: Label = $Root/BossPanel/BossNameLabel as Label


func _ready() -> void:
	GameEvents.player_health_changed.connect(_on_health_changed)
	GameEvents.player_stamina_changed.connect(_on_stamina_changed)
	GameEvents.player_ammo_changed.connect(_on_ammo_changed)
	GameEvents.player_weapon_changed.connect(_on_weapon_changed)
	GameEvents.rage_stage_changed.connect(_on_rage_stage_changed)
	GameEvents.rage_warning.connect(_on_rage_warning)
	GameEvents.room_combat_started.connect(_on_room_combat_started)
	GameEvents.room_combat_tick.connect(_on_room_combat_tick)
	GameEvents.room_cleared.connect(_on_room_cleared)
	GameEvents.boss_bar_updated.connect(_on_boss_bar_updated)
	GameEvents.boss_bar_hidden.connect(_on_boss_bar_hidden)
	RunState.coins_changed.connect(_on_run_resource_changed)
	RunState.relics_changed.connect(_refresh_relics)
	RunState.boons_changed.connect(_refresh_boons)
	BoonRuntime.active_state_changed.connect(_on_active_state_changed)
	GameState.yeouiju_changed.connect(_on_run_resource_changed)
	rage_label.text = ""
	room_label.text = ""
	_on_boss_bar_hidden()
	_refresh_run_resources()
	_refresh_relics()
	_refresh_boons()


func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = float(maximum)
	health_bar.value = float(current)


func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current


func _on_ammo_changed(current: int, magazine_size: int, reloading: bool) -> void:
	var suffix: String = " (재장전)" if reloading else ""
	ammo_label.text = "%d / %d%s" % [current, magazine_size, suffix]


## 탄약 자리는 활성 무기가 원거리일 때만 숫자를 쓴다. 근접이면 무기 이름을,
## 무기가 없으면 빈 칸을 둔다 (docs/systems/WEAPONS.md 9장 HUD 표시 계약).
## 원거리로 바뀌면 무기가 곧바로 탄약을 다시 알리므로 여기서는 지우기만 한다
func _on_weapon_changed(kind: int, display_name: String) -> void:
	if kind == Player.WeaponKind.RANGED:
		return
	ammo_label.text = display_name


func _on_rage_stage_changed(stage: int, enemy_mult: float, player_mult: float) -> void:
	if stage <= 0:
		rage_label.text = ""
		return
	rage_label.text = "생기 몰림 %d단계  적 x%.2f  나 x%.2f" % [stage, enemy_mult, player_mult]


## 발동 전 경고. 통과 기준 5(데스매치 체감) 판정에 쓴다.
func _on_rage_warning(seconds_left: float) -> void:
	rage_label.text = "생기가 고인다  %d초" % int(ceil(seconds_left))


func _on_room_combat_started(room_name: String) -> void:
	room_label.text = "%s 전투" % room_name


## M1 판정 보조: 전투 경과와 생기 몰림 발동까지 남은 시간을 상시 표시한다.
func _on_room_combat_tick(room_name: String, elapsed: float, rage_left: float) -> void:
	if rage_left > 0.0:
		room_label.text = "%s 전투 %.1f초  생기 %d초" % [room_name, elapsed, int(ceil(rage_left))]
	else:
		room_label.text = "%s 전투 %.1f초" % [room_name, elapsed]


func _on_room_cleared(room_name: String, elapsed: float) -> void:
	rage_label.text = ""
	if elapsed < 0.001:
		room_label.text = "%s 통과" % room_name
	else:
		room_label.text = "%s 클리어 %.1f초" % [room_name, elapsed]


## 유물, 권능, 노잣돈, 여의주 조각 표시 (런 상태). RunState와 GameState 시그널로 갱신한다.
## 화면 맨 아래 전폭 보스 체력바 (2026-08-10 요청). 보스가 개전할 때 뜨고 사망하거나
## 방을 벗어나면 사라진다. 방 이름 표기가 바 자리와 겹치므로 바가 뜬 동안은 위로 밀어 둔다.
func _on_boss_bar_updated(
	display_name: String, current: int, maximum: int, phase: int, phase_total: int
) -> void:
	boss_panel.visible = true
	_shift_room_label(true)
	boss_bar.max_value = float(maxi(1, maximum))
	boss_bar.value = float(current)
	if phase_total > 1:
		boss_name_label.text = "%s   %d/%d페이즈" % [display_name, phase, phase_total]
	else:
		boss_name_label.text = display_name


func _on_boss_bar_hidden() -> void:
	boss_panel.visible = false
	_shift_room_label(false)


func _shift_room_label(up: bool) -> void:
	var top: float = -45.0 if up else -18.0
	if is_equal_approx(room_label.offset_top, top):
		return
	room_label.offset_top = top
	room_label.offset_bottom = top + 13.0


func _on_run_resource_changed(_amount: int) -> void:
	_refresh_run_resources()


func _refresh_run_resources() -> void:
	run_label.text = "엽전 %d   여의주 %d" % [RunState.coins, GameState.yeouiju_shards]


func _refresh_relics() -> void:
	relic_label.text = RunState.relic_display()


func _refresh_boons() -> void:
	boon_label.text = "%s%s" % [RunState.boon_display(), _active_suffix()]


## 액티브 쿨다운 표시. 권능 표기 뒤에 붙인다 (BOONS 11장 액티브 입력 검증 항목).
func _on_active_state_changed(_ready: bool, _left: float, _total: float) -> void:
	_refresh_boons()


func _active_suffix() -> String:
	if not RunState.boons.has_active():
		return ""
	if BoonRuntime.active_ready():
		return "  [발동 준비]"
	return "  [발동 %.1f초]" % BoonRuntime.cooldown_left()
