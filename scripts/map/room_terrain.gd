@tool
class_name RoomTerrain
extends TileMapLayer

## ASCII 레이아웃을 타일로 채우는 방 지형 (DECISIONS 2026-08-04 맵 지형 전면 개편).
##
## 방 지형은 layout 문자열로 저작한다. Mac(에디터 없음)에서 텍스트로 만들고
## diff로 검토하며, 에디터에서는 @tool이라 문자열을 바꾸면 즉시 반영된다.
## 타일 선택은 이웃 기반 오토타일 (위가 비면 표면, 옆이 비면 모서리).
##
## 심볼 (docs/ROOM_SPEC.md 5장 범례):
## - G 흙길, S 석축, P 판벽, R 기와 (솔리드)
## - / 기와 경사 (오른쪽 오름), \ 기와 경사 (왼쪽 오름)
## - = 평상 (원웨이), ~ 처마 (원웨이)
## - | 지지 기둥, - 서까래 (장식. 콜리전 없음)
## - . 빈칸 (공백도 빈칸으로 취급)
##
## 파괴 좌판과 도깨비불 발판은 타일이 아니라 별도 씬 인스턴스로 배치한다.

## 지형에 걸리는 것으로 취급하는 심볼 (아래 셀의 표면/속 판정에 쓴다)
const SOLID_SYMBOLS: String = "GSPR/\\"
## 허용하는 전체 심볼
const KNOWN_SYMBOLS: String = "GSPR/\\=~|-."
## 콜리전이 없는 장식 심볼. 공중 발판에 지지 구조를 붙여 당위성을 만든다
## (docs/ROOM_SPEC.md 5장). 도달 가능성과 통행에는 영향을 주지 않는다
const DECOR_SYMBOLS: String = "|-"
## 서까래 타일 (6행 3). 이웃과 무관하게 한 종류만 쓴다
const RAFTER_TILE: Vector2i = Vector2i(3, 6)

const SOURCE_ID: int = 0
const NO_TILE: Vector2i = Vector2i(-1, -1)

## 방 지형 레이아웃. 한 줄이 한 행, 문자 하나가 타일 하나다.
@export_multiline var layout: String = "":
	set(value):
		layout = value
		_rebuild()


func _ready() -> void:
	_rebuild()


## 레이아웃 문자열을 행 배열로 만든다. 양 끝의 빈 줄은 버리고 공백은 빈칸으로 바꾼다.
static func parse_rows(text: String) -> Array[String]:
	var rows: Array[String] = []
	for line: String in text.split("\n"):
		rows.append(line.replace(" ", "."))
	while not rows.is_empty() and rows[0].strip_edges() == "":
		rows.remove_at(0)
	while not rows.is_empty() and rows[rows.size() - 1].strip_edges() == "":
		rows.remove_at(rows.size() - 1)
	return rows


## (x, y) 셀의 심볼. 범위 밖은 빈칸으로 본다.
static func symbol_at(rows: Array[String], x: int, y: int) -> String:
	if y < 0 or y >= rows.size():
		return "."
	var row: String = rows[y]
	if x < 0 or x >= row.length():
		return "."
	return row[x]


## 그 셀이 솔리드 지형인지 (표면/속 판정용. 원웨이는 지형으로 세지 않는다).
static func is_solid(rows: Array[String], x: int, y: int) -> bool:
	return SOLID_SYMBOLS.contains(symbol_at(rows, x, y))


## (x, y) 셀에 놓을 아틀라스 좌표. 빈칸이면 NO_TILE.
## 아틀라스 배치는 tools/pipeline/gen_tileset_act1.py와 일치해야 한다.
static func atlas_for(rows: Array[String], x: int, y: int) -> Vector2i:
	var symbol: String = symbol_at(rows, x, y)
	match symbol:
		"G":
			return _atlas_earth(rows, x, y)
		"S":
			return _atlas_block(rows, x, y, 1)
		"P":
			return _atlas_block(rows, x, y, 2)
		"R":
			return _atlas_roof(rows, x, y)
		"/":
			return Vector2i(6, 3)
		"\\":
			return Vector2i(7, 3)
		"=":
			return _atlas_strip(rows, x, y, "=", 4)
		"~":
			return _atlas_strip(rows, x, y, "~", 5)
		"|":
			return _atlas_post(rows, x, y)
		"-":
			return RAFTER_TILE
	return NO_TILE


## 레이아웃에서 심볼이 놓인 셀 좌표 목록 (검증, 테스트용).
static func cells_of(rows: Array[String], symbols: String) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y: int in rows.size():
		for x: int in rows[y].length():
			if symbols.contains(rows[y][x]):
				found.append(Vector2i(x, y))
	return found


## 알 수 없는 심볼 목록 (검증용. 비어 있어야 정상).
static func unknown_symbols(rows: Array[String]) -> Array[String]:
	var bad: Array[String] = []
	for row: String in rows:
		for i: int in row.length():
			var symbol: String = row[i]
			if not KNOWN_SYMBOLS.contains(symbol) and not bad.has(symbol):
				bad.append(symbol)
	return bad


## 지지 기둥 (6행 0~2). 위가 발판이면 까치발 상단, 아래가 지형이면 주춧돌 밑동, 나머지는 몸통.
static func _atlas_post(rows: Array[String], x: int, y: int) -> Vector2i:
	var above: String = symbol_at(rows, x, y - 1)
	var below: String = symbol_at(rows, x, y + 1)
	if above != "|" and (SOLID_SYMBOLS.contains(above) or "=~".contains(above)):
		return Vector2i(0, 6)
	if SOLID_SYMBOLS.contains(below):
		return Vector2i(2, 6)
	return Vector2i(1, 6)


## 흙길 (0행). 표면 변형 2종, 모서리, 속 변형 2종, 좌우 가장자리.
static func _atlas_earth(rows: Array[String], x: int, y: int) -> Vector2i:
	var variant: int = (x * 7 + y * 13) % 2
	if not is_solid(rows, x, y - 1):
		if not is_solid(rows, x - 1, y):
			return Vector2i(2, 0)
		if not is_solid(rows, x + 1, y):
			return Vector2i(3, 0)
		return Vector2i(variant, 0)
	if not is_solid(rows, x - 1, y):
		return Vector2i(6, 0)
	if not is_solid(rows, x + 1, y):
		return Vector2i(7, 0)
	return Vector2i(4 + variant, 0)


## 석축(row=1)과 판벽(row=2). 배치가 같아 행만 다르다.
static func _atlas_block(rows: Array[String], x: int, y: int, atlas_row: int) -> Vector2i:
	var open_up: bool = not is_solid(rows, x, y - 1)
	var open_left: bool = not is_solid(rows, x - 1, y)
	var open_right: bool = not is_solid(rows, x + 1, y)
	if open_up and open_left and open_right:
		return Vector2i(7, atlas_row)
	if open_up:
		if open_left:
			return Vector2i(1, atlas_row)
		if open_right:
			return Vector2i(2, atlas_row)
		return Vector2i(0, atlas_row)
	if open_left:
		return Vector2i(5, atlas_row)
	if open_right:
		return Vector2i(6, atlas_row)
	return Vector2i(3 + (x * 7 + y * 13) % 2, atlas_row)


## 기와 (3행). 위가 비면 마루(걷는 면), 아니면 지붕 밑 속.
static func _atlas_roof(rows: Array[String], x: int, y: int) -> Vector2i:
	var open_left: bool = not is_solid(rows, x - 1, y)
	var open_right: bool = not is_solid(rows, x + 1, y)
	if not is_solid(rows, x, y - 1):
		if open_left:
			return Vector2i(1, 3)
		if open_right:
			return Vector2i(2, 3)
		return Vector2i(0, 3)
	if open_left:
		return Vector2i(4, 3)
	if open_right:
		return Vector2i(5, 3)
	return Vector2i(3, 3)


## 평상(4행)과 처마(5행). 같은 심볼의 좌우 연속으로 끝단을 고른다.
static func _atlas_strip(
	rows: Array[String], x: int, y: int, symbol: String, atlas_row: int
) -> Vector2i:
	var joined_left: bool = symbol_at(rows, x - 1, y) == symbol
	var joined_right: bool = symbol_at(rows, x + 1, y) == symbol
	if joined_left and joined_right:
		return Vector2i(1, atlas_row)
	if joined_right:
		return Vector2i(0, atlas_row)
	if joined_left:
		return Vector2i(2, atlas_row)
	return Vector2i(3, atlas_row)


func _rebuild() -> void:
	if not is_node_ready():
		return
	clear()
	var rows: Array[String] = parse_rows(layout)
	var bad: Array[String] = unknown_symbols(rows)
	if not bad.is_empty():
		push_warning("레이아웃에 알 수 없는 심볼: %s" % str(bad))
	for y: int in rows.size():
		for x: int in rows[y].length():
			var atlas: Vector2i = atlas_for(rows, x, y)
			if atlas != NO_TILE:
				set_cell(Vector2i(x, y), SOURCE_ID, atlas)
