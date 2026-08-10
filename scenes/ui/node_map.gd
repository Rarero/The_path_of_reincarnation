class_name NodeMap
extends Control

## 지도(노드 선택 화면) 오버레이. docs/RUN_STRUCTURE.md 2, 7장, 요청서 020.
##
## 양손으로 펼쳐 든 옛 조선 지도(PixelLab 생성, 손과 종이가 한 장)를 전체화면 배경으로
## 깔고, 그 위에 동람도식 방표(세로 팻말)를 무채색 먹으로 그린다. 노드는 사물이 아니라
## 인상을 전한다: 위험(전투), 매우 위험(중간보스), 알 수 없음(이벤트/내기), 좋음(상점/
## 쉼터), 신비(신당), 보스(막 보스, 읍성 방표).
##
## 2026-08-10 지도의 길을 전부 긋는다. 종전에는 현재 위치에서 갈 수 있는 곳으로만 점선을
## 찍어, 지도가 어떻게 이어져 있는지 읽을 수 없었다. 옛 지도의 도로 표기를 따른다.
## 현재 = 먹 이중 테, 선택 가능 = 종이색 후광 + 먹 점선 테, 지나온 곳 = 붓 동그라미.
## 자유 이동이라 한 노드가 지나온 곳이면서 갈 수 있는 곳일 수 있다. 그래서 두 표시를
## 서로 다른 채널(면과 선)로 나눠 겹쳐도 읽히게 했다 (2026-08-10)
## 노드 좌표는 RunMap이 정한다 (2026-08-06 자유 이동 전환). 여기서는 배경 명도를
## 샘플링해 산수와 손을 피하고 기호끼리 밀어내 겹침만 막는다. 조작은 마우스와 키보드.

## 다음 노드를 골랐다. node_id
signal node_chosen(node_id: int)

## 배경 원본(map_paper.png, 440x240)을 비정수 스케일 없이 원본 크기로 붙인다.
## 종이와 손 바깥은 투명(에셋에서 크림 배경 제거)이라 뒤에 멈춘 전투 맵이 어둡게 비친다.
## 화면 480x270 정중앙에 놓는다: 좌우 여백 20, 상하 여백 15 (2026-08-06 정렬 보정.
## 종전 y=30은 320x180 시절 좌표가 남은 것으로 종이가 아래로 붙어 있었다)
const PAPER_POS: Vector2 = Vector2(20, 15)
const PAPER_SIZE: Vector2 = Vector2(440, 240)
## 아래 배치 좌표는 화면 절대 좌표다. PAPER_POS를 옮기면 y도 같은 만큼 따라가야 한다
## 기호 아이콘 반크기 (16x16 독도법 기호를 지도에 직접 얹는다, 방표 틀 없음).
## 2026-08-06 22px에서 16px로 축소. 22px는 기호가 커서 서로 붙어 보였다
const ICON_HALF: float = 8.0
const RING_RADIUS: float = 11.0
## 마우스 판정 반경. 기호가 작아진 만큼 판정은 조금 넉넉하게 둔다
const HIT_RADIUS: float = 13.0
## 기호 중심 사이 최소 간격 (px). 테두리(반경 11) 둘이 10px 떨어지는 값이다.
## RunMap.MIN_SEPARATION과 같은 값이어야 배치와 표시가 어긋나지 않는다
const MIN_SEP: float = 32.0
## 배경 회피: 이 명도 이상이면 빈 종이로 보고 노드를 놓는다 (아래면 산수나 손으로 판단)
const LUMA_OK: float = 0.66
## 배경 회피 탐색 최대 반경 (px)
const AVOID_MAX: int = 34
## 노드를 놓을 수 있는 종이 안쪽 영역 (PAPER_POS 기준 상대 (70, 32) 크기 296x176)
const FIELD: Rect2 = Rect2(90, 47, 296, 176)
const OPEN_TIME: float = 0.5
const CLOSE_TIME: float = 0.22

const INK: Color = Color(0.18, 0.14, 0.11)
const INK_SOFT: Color = Color(0.42, 0.35, 0.27)
const PARCH: Color = Color(0.93, 0.90, 0.82)
## 생기 고갈 경고 글자색. 먹보다 눈에 띄되 적색(생기 몰림 전용)은 피한다
const INK_ALERT: Color = Color(0.42, 0.20, 0.16)

## 길 표기 (2026-08-10). 옛 지도의 도로처럼 가는 먹선 한 줄로 긋는다.
## 산수와 손 위에서도 선이 끊겨 보이지 않도록 종이색 깔개를 먼저 깔고 그 위에 먹을 얹는다
const ROAD_BED: Color = Color(0.933, 0.906, 0.831)
const ROAD_BED_WIDTH: float = 3.0
## 그냥 길. 가늘다
const ROAD_INK: Color = Color(0.275, 0.212, 0.149)
const ROAD_WIDTH: float = 1.0
## 이미 밟은 길. 점선이 아니라 실선이다. 발길에 다져져 자국이 이어진 길이라는 뜻이고,
## 굵기나 색으로 나누면 갈 수 있는 길과 헷갈려서 선의 종류 자체를 바꿨다 (2026-08-10)
const ROAD_WALKED_INK: Color = Color(0.235, 0.173, 0.118)
const ROAD_WALKED_WIDTH: float = 1.0
## 지금 갈 수 있는 길. 굵고 진한 데다 십리점이 찍힌다
const ROAD_OPEN_INK: Color = Color(0.118, 0.094, 0.067)
const ROAD_OPEN_WIDTH: float = 2.0
## 길이 크게 휘는 폭 (px). 간선 id로 결정적이라 같은 지도는 같은 굽이를 재현한다
const ROAD_SAG: float = 2.5
## 길이 잘게 구불거리는 폭과 물결 수. 끝에서는 0이 되어 노드에 곧게 닿는다
const ROAD_WAVE: float = 2.2
const ROAD_WAVE_MIN: float = 1.5
const ROAD_WAVE_MAX: float = 2.5
## 곡선을 나눌 길이 (px). 작을수록 매끄럽고 그리는 양이 는다
const ROAD_STEP: float = 2.0
## 점선 한 칸과 사이 간격 (px). 2026-08-10 칸 3 사이 4.5로 잡았다가 성겨서 사이를 3으로 줄였다
const ROAD_DASH: float = 3.0
const ROAD_GAP: float = 3.0
## 십리점 반지름 (px). 바깥 테는 종이색이라 먹선 위에서도 점이 보인다
const RI_DOT_OUTER: float = 2.0
const RI_DOT_INNER: float = 1.0
## 갈 수 있는 노드 뒤에 까는 후광. 지나온 표시(붓 동그라미)와 채널이 달라(면과 선)
## 한 노드가 둘 다여도 읽힌다. 종이보다 밝게 하면 배경이 이미 밝아 보이지 않으므로
## 옅은 흙빛으로 어둡게 깐다 (2026-08-10)
const SELECT_HALO: Color = Color(0.776, 0.714, 0.588, 0.55)
const SELECT_HALO_RADIUS: float = 13.5

var _run_map: RunMap = null
var _selectable: Array[int] = []
var _sel_index: int = 0
var _pos: Dictionary = {}
var _icons: Dictionary = {}
var _labels: Dictionary = {}
var _paper: Texture2D = null
var _paper_img: Image = null
var _is_open: bool = false
var _unfold: float = 0.0
var _dim: float = 0.0
var _pulse_time: float = 0.0


func _ready() -> void:
	_load_art()
	visible = false
	set_process(false)


func _load_art() -> void:
	var paper_path: String = "res://assets/sprites/ui/map_paper.png"
	if ResourceLoader.exists(paper_path):
		_paper = load(paper_path)
		_paper_img = _paper.get_image() if _paper != null else null
	var icon_paths: Dictionary = {
		RunMap.Kind.COMBAT: "res://assets/sprites/ui/nodes/danger.png",
		RunMap.Kind.MIDBOSS: "res://assets/sprites/ui/nodes/peril.png",
		RunMap.Kind.EVENT: "res://assets/sprites/ui/nodes/unknown.png",
		RunMap.Kind.GAMBLE: "res://assets/sprites/ui/nodes/unknown.png",
		RunMap.Kind.SHOP: "res://assets/sprites/ui/nodes/boon.png",
		RunMap.Kind.REST: "res://assets/sprites/ui/nodes/boon.png",
		RunMap.Kind.SHRINE: "res://assets/sprites/ui/nodes/mystery.png",
		RunMap.Kind.BOSS: "res://assets/sprites/ui/nodes/boss.png",
	}
	for kind: int in icon_paths:
		var path: String = icon_paths[kind]
		if ResourceLoader.exists(path):
			_icons[kind] = load(path)
	# 2026-08-06 인상 표기(위험, 좋음, 신비)를 방 이름으로 바꿨다.
	# 노드 종류는 지도 전체 공개가 원칙이라(docs/RUN_STRUCTURE.md 2장) 이름이 맞다
	_labels = {
		RunMap.Kind.COMBAT: "전투",
		RunMap.Kind.MIDBOSS: "중간보스",
		RunMap.Kind.EVENT: "미지",
		RunMap.Kind.GAMBLE: "내기",
		RunMap.Kind.SHOP: "상점",
		RunMap.Kind.REST: "쉼터",
		RunMap.Kind.SHRINE: "신당",
		RunMap.Kind.BOSS: "보스",
	}


func _process(delta: float) -> void:
	if not _is_open:
		return
	_pulse_time += delta
	queue_redraw()


## 지도를 연다. 진행 흐름상 귀문 진입 시 호출한다.
func open(map: RunMap) -> void:
	_run_map = map
	_compute_layout()
	_selectable = map.selectable_next_ids()
	_sel_index = 0
	_is_open = true
	_pulse_time = 0.0
	_unfold = 0.0
	_dim = 0.0
	visible = true
	set_process(true)
	var tween: Tween = create_tween()
	tween.tween_method(_set_dim, 0.0, 1.0, CLOSE_TIME)
	var roll: MethodTweener = tween.parallel().tween_method(_set_unfold, 0.0, 1.0, OPEN_TIME)
	roll.set_trans(Tween.TRANS_BACK)
	roll.set_ease(Tween.EASE_OUT)
	queue_redraw()


func close() -> void:
	_is_open = false
	visible = false
	set_process(false)


func _set_unfold(value: float) -> void:
	_unfold = value
	queue_redraw()


func _set_dim(value: float) -> void:
	_dim = value
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not _is_open or _selectable.is_empty():
		return
	if event.is_action_pressed(&"move_up") or event.is_action_pressed(&"ui_up"):
		_move_selection(-1)
	elif event.is_action_pressed(&"move_down") or event.is_action_pressed(&"ui_down"):
		_move_selection(1)
	elif _is_confirm(event):
		_confirm()
	elif event is InputEventMouseMotion:
		_hover_at(get_local_mouse_position())
	elif event is InputEventMouseButton and _is_left_click(event):
		if _click_at(get_local_mouse_position()):
			_confirm()


func _is_confirm(event: InputEvent) -> bool:
	return (
		event.is_action_pressed(&"jump")
		or event.is_action_pressed(&"attack_ranged")
		or event.is_action_pressed(&"ui_accept")
	)


func _is_left_click(event: InputEventMouseButton) -> bool:
	return event.pressed and event.button_index == MOUSE_BUTTON_LEFT


func _move_selection(step: int) -> void:
	var count: int = _selectable.size()
	_sel_index = (_sel_index + step + count) % count
	AudioDirector.play_sfx(AudioDirector.Sfx.UI_SELECT)
	get_viewport().set_input_as_handled()
	queue_redraw()


func _hover_at(point: Vector2) -> void:
	for i: int in range(_selectable.size()):
		if point.distance_to(_node_pos(_selectable[i])) <= HIT_RADIUS:
			if _sel_index != i:
				_sel_index = i
				queue_redraw()
			return


func _click_at(point: Vector2) -> bool:
	for i: int in range(_selectable.size()):
		if point.distance_to(_node_pos(_selectable[i])) <= HIT_RADIUS:
			_sel_index = i
			return true
	return false


func _confirm() -> void:
	if not _is_open or _selectable.is_empty():
		return
	var chosen: int = _selectable[_sel_index]
	AudioDirector.play_sfx(AudioDirector.Sfx.UI_SELECT)
	_is_open = false
	get_viewport().set_input_as_handled()
	var tween: Tween = create_tween()
	tween.tween_method(_set_unfold, _unfold, 0.0, CLOSE_TIME)
	tween.parallel().tween_method(_set_dim, _dim, 0.0, CLOSE_TIME)
	await tween.finished
	visible = false
	set_process(false)
	node_chosen.emit(chosen)


# --- 배치 ---


func _compute_layout() -> void:
	_pos.clear()
	if _run_map == null or _run_map.nodes.is_empty():
		return
	# 노드 좌표는 RunMap이 이미 지도 영역(FIELD 크기) 기준으로 흩뿌려 뒀다.
	# 여기서는 종이 위치만 더하고 산수와 손을 피해 미세 조정한다
	for node: RunMapNode in _run_map.nodes:
		_pos[node.id] = _relocate_to_light(FIELD.position + node.pos)
	_separate_nodes()


## node.id와 시드로 만든 결정적 지터 (-1..1). 같은 맵은 같은 삐뚤빼뚤 배치를 재현한다.
func _hash_signed(n: int) -> float:
	var h: float = sin(float(n) * 12.9898 + 78.233) * 43758.5453
	return (h - floor(h)) * 2.0 - 1.0


## 배경(산수, 손)과 겹치면 가장 가까운 빈 종이로 옮긴다. 중심 쪽을 살짝 선호한다.
func _relocate_to_light(pos: Vector2) -> Vector2:
	if _paper_img == null:
		return pos
	if _in_field(pos) and _min_luma(pos) >= LUMA_OK:
		return pos
	var center_x: float = PAPER_POS.x + PAPER_SIZE.x * 0.5
	var best: Vector2 = pos
	var best_score: float = -1.0
	var radius: int = 4
	while radius <= AVOID_MAX:
		for deg: int in range(0, 360, 15):
			var angle: float = deg_to_rad(float(deg))
			var cand: Vector2 = pos + Vector2(cos(angle), sin(angle)) * float(radius)
			if not _in_field(cand):
				continue
			var luma: float = _min_luma(cand)
			if luma >= LUMA_OK:
				var score: float = luma - absf(cand.x - center_x) / 4000.0
				if score > best_score:
					best_score = score
					best = cand
		if best_score >= 0.0:
			return best
		radius += 3
	return pos


## 방표끼리 겹치지 않게 서로 밀어낸다 (결정적 완화 패스).
func _separate_nodes() -> void:
	var ids: Array = _pos.keys()
	for _pass: int in range(24):
		var moved: bool = false
		for i: int in range(ids.size()):
			for j: int in range(i + 1, ids.size()):
				var a: int = ids[i]
				var b: int = ids[j]
				var delta: Vector2 = _pos[b] - _pos[a]
				var dist: float = delta.length()
				if dist < 0.01:
					delta = Vector2(1, 0)
					dist = 1.0
				if dist >= MIN_SEP:
					continue
				var push: Vector2 = delta / dist * (MIN_SEP - dist) * 0.5
				var new_a: Vector2 = _pos[a] - push
				var new_b: Vector2 = _pos[b] + push
				# 산수 위로 밀리더라도 기호끼리 겹치는 것보다 낫다. 임계를 크게 늦춘다
				if _in_field(new_a):
					_pos[a] = new_a
				if _in_field(new_b):
					_pos[b] = new_b
				moved = true
		if not moved:
			return


## 노드 자리 주변의 가장 어두운 명도. 낮을수록 산수나 손 위라는 뜻.
func _min_luma(pos: Vector2) -> float:
	if _paper_img == null:
		return 1.0
	var width: int = _paper_img.get_width()
	var height: int = _paper_img.get_height()
	var darkest: float = 1.0
	for ox: int in [-11, -5, 0, 5, 11]:
		for oy: int in [-12, -6, 0, 6, 12]:
			var u: float = (pos.x + float(ox) - PAPER_POS.x) / PAPER_SIZE.x
			var v: float = (pos.y + float(oy) - PAPER_POS.y) / PAPER_SIZE.y
			if u < 0.0 or u > 1.0 or v < 0.0 or v > 1.0:
				continue
			var ix: int = int(clampf(u * float(width - 1), 0.0, float(width - 1)))
			var iy: int = int(clampf(v * float(height - 1), 0.0, float(height - 1)))
			var color: Color = _paper_img.get_pixel(ix, iy)
			darkest = minf(darkest, (color.r + color.g + color.b) / 3.0)
	return darkest


func _in_field(pos: Vector2) -> bool:
	return FIELD.has_point(pos)


func _node_pos(node_id: int) -> Vector2:
	return _pos.get(node_id, Vector2.ZERO)


# --- 그리기 ---


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.6 * _dim))
	if _run_map == null:
		return
	var rise: float = (1.0 - _unfold) * 14.0
	draw_set_transform(Vector2(0.0, rise), 0.0, Vector2.ONE)
	_draw_paper()
	var reveal_x: float = PAPER_POS.x + PAPER_SIZE.x * _unfold
	_draw_roads(reveal_x)
	_draw_nodes(reveal_x)
	if _unfold > 0.9:
		_draw_budget()
		_draw_cursor_label()


## 명줄(이동 예산) 표시 (docs/RUN_STRUCTURE.md 11.7 노드 맵 UI).
## 이동 예산이 자유 이동의 유일한 통제 장치인데 값이 화면에 없으면
## 플레이어가 무엇을 아끼는지 알 수 없다. 남은 명줄, 이번 이동 비용,
## 이동 후 잔량을 한 줄로 붙여 둔다. 고갈 상태면 단계를 함께 알린다
func _draw_budget() -> void:
	if _run_map == null:
		return
	var left: int = _run_map.budget_left()
	var text: String = "명줄 %d" % left
	if not _selectable.is_empty():
		var target: int = _selectable[_sel_index]
		var cost: int = _run_map.move_cost_from_current(target)
		if cost >= 0:
			text = "명줄 %d   이 걸음 %d   남을 명줄 %d" % [left, cost, _run_map.budget_after(target)]
	var stage: int = _run_map.depletion_stage()
	if stage > 0:
		text = "%s   생기 고갈 %d단계" % [text, stage]
	var font: Font = get_theme_default_font()
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9).x
	var box: Rect2 = Rect2(PAPER_POS.x + 12.0, PAPER_POS.y + 10.0, width + 8.0, 13.0)
	draw_rect(box, PARCH)
	draw_rect(box, INK, false, 1.0)
	draw_string(
		font,
		box.position + Vector2(4.0, 10.0),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		9,
		INK if stage <= 0 else INK_ALERT
	)


func _draw_paper() -> void:
	var alpha: float = clampf(_unfold * 2.5, 0.0, 1.0)
	if _paper == null:
		draw_rect(Rect2(PAPER_POS, PAPER_SIZE), Color(0.87, 0.82, 0.71, alpha))
		return
	draw_texture_rect(_paper, Rect2(PAPER_POS, PAPER_SIZE), false, Color(1, 1, 1, alpha))


## 지도의 길을 전부 긋는다 (docs/RUN_STRUCTURE.md 11.7).
##
## 어디와 어디가 이어져 있는지가 자유 이동 지도에서 가장 먼저 읽혀야 하는 정보다.
## 옛 지도(대동여지도)의 도로 표기를 따라 가는 먹선 한 줄로 긋고, 종이색 깔개를 먼저
## 깔아 산수와 손 위에서도 선이 끊겨 보이지 않게 한다.
##
## 세 등급을 굵기와 십리점으로 나눈다. 색만으로 나누면 이 크기에서 구분되지 않는다.
## 가는 선 = 그냥 길, 굵은 선 = 이미 지나온 길, 굵은 선에 십리점 = 지금 갈 수 있는 길.
## 십리점 하나가 이동 비용 1이라 숫자를 적지 않아도 걸음 값이 눈으로 읽힌다
func _draw_roads(reveal_x: float) -> void:
	var current_id: int = _run_map.current_id()
	var roads: Array = []
	for node: RunMapNode in _run_map.nodes:
		for other_id: int in node.link_ids:
			if other_id <= node.id:
				continue
			var a: Vector2 = _node_pos(node.id)
			var b: Vector2 = _node_pos(other_id)
			if a.x > reveal_x or b.x > reveal_x:
				continue
			var line: PackedVector2Array = _road_points(a, b, node.id * 97 + other_id)
			roads.append(
				{
					"points": line,
					"dashes": _dash_segments(line),
					"walked": _run_map.is_walked(node.id, other_id),
					"open": node.id == current_id or other_id == current_id,
					"cost": _run_map.move_cost(node.id, other_id),
				}
			)
	for road: Dictionary in roads:
		if bool(road["walked"]) and not bool(road["open"]):
			draw_polyline(road["points"], ROAD_BED, ROAD_BED_WIDTH)
		else:
			_draw_dashes(road["dashes"], ROAD_BED, ROAD_BED_WIDTH)
	for road: Dictionary in roads:
		if bool(road["open"]):
			continue
		if bool(road["walked"]):
			draw_polyline(road["points"], ROAD_WALKED_INK, ROAD_WALKED_WIDTH)
		else:
			_draw_dashes(road["dashes"], ROAD_INK, ROAD_WIDTH)
	for road: Dictionary in roads:
		if not bool(road["open"]):
			continue
		_draw_dashes(road["dashes"], ROAD_OPEN_INK, ROAD_OPEN_WIDTH)
		_draw_ri_dots(road["points"], int(road["cost"]))


## 결정적으로 굽은 길의 꼭짓점.
##
## 두 겹이다. 2차 베지에로 길 전체를 한 번 크게 휘고(ROAD_SAG), 그 위에 낮은 물결을
## 얹어 잘게 구불거리게 한다(ROAD_WAVE). 물결은 sin(t * PI) 봉투를 씌워 양 끝에서 0이
## 되므로 길이 노드에는 곧게 닿는다. 전부 간선 id로 결정적이라 같은 지도는 같은 굽이다
func _road_points(a: Vector2, b: Vector2, edge_id: int) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var direction: Vector2 = b - a
	var length: float = direction.length()
	if length < 1.0:
		out.append(a)
		out.append(b)
		return out
	var normal: Vector2 = Vector2(-direction.y, direction.x) / length
	var control: Vector2 = (a + b) * 0.5 + normal * _hash_signed(edge_id * 3) * ROAD_SAG
	var waves: float = lerpf(
		ROAD_WAVE_MIN, ROAD_WAVE_MAX, (_hash_signed(edge_id * 7) + 1.0) * 0.5
	)
	var phase: float = _hash_signed(edge_id * 11) * PI
	var steps: int = maxi(8, int(length / ROAD_STEP))
	for i: int in range(steps + 1):
		var t: float = float(i) / float(steps)
		var one: float = 1.0 - t
		var base: Vector2 = one * one * a + 2.0 * one * t * control + t * t * b
		var wobble: float = sin(t * TAU * waves + phase) * sin(t * PI) * ROAD_WAVE
		out.append(base + normal * wobble)
	return out


## 길을 점선으로 자른다. 호 길이를 따라 ROAD_DASH만큼 긋고 ROAD_GAP만큼 쉰다.
func _dash_segments(points: PackedVector2Array) -> Array:
	var dashes: Array = []
	if points.size() < 2:
		return dashes
	var current: PackedVector2Array = PackedVector2Array()
	var drawing: bool = true
	var run: float = 0.0
	current.append(points[0])
	for i: int in range(1, points.size()):
		run += points[i - 1].distance_to(points[i])
		var limit: float = ROAD_DASH if drawing else ROAD_GAP
		if drawing:
			current.append(points[i])
		if run < limit:
			continue
		run = 0.0
		if drawing:
			if current.size() >= 2:
				dashes.append(current)
			current = PackedVector2Array()
		else:
			current = PackedVector2Array()
			current.append(points[i])
		drawing = not drawing
	if drawing and current.size() >= 2:
		dashes.append(current)
	return dashes


## 점선 한 벌을 긋는다.
func _draw_dashes(dashes: Array, color: Color, width: float) -> void:
	for dash: PackedVector2Array in dashes:
		draw_polyline(dash, color, width)


## 십리점. 옛 지도가 도로에 십 리마다 점을 찍어 거리를 알린 표기다.
## 여기서는 점 하나가 이동 비용 1이다 (RunMap.COST_UNIT 9px마다 하나).
func _draw_ri_dots(points: PackedVector2Array, cost: int) -> void:
	if cost <= 1 or points.size() < 2:
		return
	for i: int in range(1, cost):
		var t: float = float(i) / float(cost)
		var index: int = clampi(int(t * float(points.size() - 1)), 0, points.size() - 1)
		draw_circle(points[index], RI_DOT_OUTER, PARCH)
		draw_circle(points[index], RI_DOT_INNER, ROAD_OPEN_INK)


func _draw_nodes(reveal_x: float) -> void:
	for node: RunMapNode in _run_map.nodes:
		var point: Vector2 = _node_pos(node.id)
		if point.x > reveal_x:
			continue
		var current: bool = _run_map.is_current(node.id)
		if not current and _selectable.has(node.id):
			draw_circle(point, SELECT_HALO_RADIUS, SELECT_HALO)
		_draw_symbol(node, point)
		if current:
			draw_arc(point, RING_RADIUS, 0.0, TAU, 28, INK, 2.0)
			draw_arc(point, RING_RADIUS + 3.0, 0.0, TAU, 28, INK_SOFT, 1.0)
		elif _selectable.has(node.id):
			# 자유 이동이라 직전에 있던 노드는 방문 표시와 선택 가능 표시를 동시에 만족한다.
			# 갈 수 있다는 사실이 더 중요하므로 점선 테를 먼저 준다 (2026-08-06 전환).
			# 되짚어 갈 수 있는 곳이라는 것을 붓 동그라미로 함께 알린다
			_draw_dashed_ring(point)
			if node.visited:
				_draw_brush_circle(point, node.id)
		elif node.visited:
			_draw_brush_circle(point, node.id)
	if not _selectable.is_empty():
		_draw_cursor(_node_pos(_selectable[_sel_index]))


## 독도법 기호를 지도에 직접 얹는다 (동람도 원형, 방표 틀 없음).
## 봉수=위험, 쌍봉수=매우 위험, 안개=알 수 없음, 역참 초가=좋음, 신당 문=신비, 읍성=보스.
func _draw_symbol(node: RunMapNode, point: Vector2) -> void:
	var tex: Texture2D = _icons.get(node.kind, null)
	if tex == null:
		draw_circle(point, 4.0, INK)
		return
	draw_texture(tex, point - tex.get_size() * 0.5)


## 지나온 곳 표시: 붓으로 한 번에 두른 동그라미 (선종 원상. 2026-08-06 참고 이미지 반영).
## 특징 넷을 재현한다. 붓압에 따라 굵기가 변하고, 한 바퀴를 살짝 넘겨 시작과 끝이 겹치며,
## 마른 붓 자리에서 획이 끊기고, 반지름이 고르지 않다. 전부 노드 id로 결정적이다.
func _draw_brush_circle(point: Vector2, node_id: int) -> void:
	var seed_f: float = float(node_id)
	var segments: int = 72
	var start: float = _hash_signed(node_id * 7) * TAU
	# 한 바퀴를 조금 넘겨 그어 시작과 끝이 스쳐 지나간다
	var sweep: float = TAU * (1.09 + _hash_signed(node_id * 11) * 0.07)
	var base: float = RING_RADIUS - 1.0
	var previous: Vector2 = Vector2.ZERO
	var has_previous: bool = false
	for i: int in range(segments + 1):
		var t: float = float(i) / float(segments)
		var angle: float = start + t * sweep
		var wobble: float = (
			sin(angle * 2.0 + seed_f) * 1.1 + sin(angle * 5.0 + seed_f * 0.7) * 0.45
		)
		var current: Vector2 = point + Vector2(cos(angle), sin(angle)) * (base + wobble)
		# 붓압: 들어갈 때 가늘고 중간이 굵고 뗄 때 다시 가늘다
		var press: float = sin(t * PI)
		var width: float = 1.0 + 2.7 * press + sin(angle * 3.0 + seed_f * 1.3) * 0.5
		# 마른 붓: 획이 끊기는 구간. 붓압이 실린 구간은 잘 끊기지 않는다
		var dry: float = sin(angle * 4.0 + seed_f * 2.1) + sin(angle * 9.0 + seed_f)
		if has_previous and not (dry < -0.95 and press < 0.85):
			draw_line(previous, current, INK, maxf(0.8, width))
		previous = current
		has_previous = true
	_draw_brush_speckles(point, node_id, base)


## 마른 붓이 튄 자국. 획 바깥쪽에 점을 몇 개 흩어 손맛을 낸다.
func _draw_brush_speckles(point: Vector2, node_id: int, base: float) -> void:
	for i: int in range(5):
		var angle: float = _hash_signed(node_id * 17 + i) * TAU
		var offset: float = base + 1.0 + absf(_hash_signed(node_id * 23 + i)) * 2.5
		var spot: Vector2 = point + Vector2(cos(angle), sin(angle)) * offset
		draw_rect(Rect2(spot, Vector2.ONE), INK)


func _draw_dashed_ring(point: Vector2) -> void:
	for deg: int in range(0, 360, 30):
		draw_arc(
			point, RING_RADIUS, deg_to_rad(float(deg)), deg_to_rad(float(deg) + 15.0), 6, INK, 1.5
		)


func _draw_cursor(point: Vector2) -> void:
	var bob: float = 1.0 + 0.5 * sin(_pulse_time * 6.0)
	var tip: Vector2 = point + Vector2(0.0, -RING_RADIUS - 3.0 - bob)
	var a: Vector2 = tip + Vector2(-3.5, -5.0)
	var b: Vector2 = tip + Vector2(3.5, -5.0)
	draw_colored_polygon(PackedVector2Array([tip, a, b]), INK)


func _draw_cursor_label() -> void:
	if _selectable.is_empty():
		return
	var node: RunMapNode = _run_map.get_node_by_id(_selectable[_sel_index])
	if node == null:
		return
	# 방 이름만 보여준다. 이벤트의 좋고 나쁨 확률은 지도에 노출하지 않는다
	# (2026-08-06 게이지 제거. 미지라고 부르면서 확률을 붙이면 표기가 서로 어긋난다)
	var text: String = String(_labels.get(node.kind, "?"))
	var font: Font = get_theme_default_font()
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9).x
	var point: Vector2 = _node_pos(node.id)
	var box: Rect2 = Rect2(
		point.x - width * 0.5 - 3.0, point.y - RING_RADIUS - 20.0, width + 6.0, 12.0
	)
	box.position.x = clampf(box.position.x, FIELD.position.x, FIELD.end.x - box.size.x)
	# 위쪽 노드는 라벨이 종이 밖으로 나간다. 그럴 때는 노드 아래로 뒤집는다
	if box.position.y < PAPER_POS.y + 4.0:
		box.position.y = point.y + RING_RADIUS + 6.0
	draw_rect(box, PARCH)
	draw_rect(box, INK, false, 1.0)
	draw_string(
		font, box.position + Vector2(3.0, 9.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, INK
	)
