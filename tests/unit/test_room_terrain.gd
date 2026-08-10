extends GdUnitTestSuite

## 방 지형 레이아웃 규칙 검증 (scripts/map/room_terrain.gd).
##
## 파싱과 오토타일 선택의 순수 로직만 고정한다.
## 실제 콜리전과 조작 체감은 Windows 플레이 테스트로 검증한다.

const SAMPLE: String = """
SSSS
S..S
S==S
GGGG
"""


func test_parse_rows_trims_blank_edges_and_spaces() -> void:
	var rows: Array[String] = RoomTerrain.parse_rows("\n\nG G\n..\n\n")
	assert_int(rows.size()).is_equal(2)
	assert_str(rows[0]).is_equal("G.G")
	assert_str(rows[1]).is_equal("..")


func test_symbol_at_out_of_range_is_empty() -> void:
	var rows: Array[String] = RoomTerrain.parse_rows(SAMPLE)
	assert_str(RoomTerrain.symbol_at(rows, -1, 0)).is_equal(".")
	assert_str(RoomTerrain.symbol_at(rows, 0, 99)).is_equal(".")
	assert_str(RoomTerrain.symbol_at(rows, 0, 0)).is_equal("S")


func test_oneway_is_not_solid() -> void:
	var rows: Array[String] = RoomTerrain.parse_rows(SAMPLE)
	assert_bool(RoomTerrain.is_solid(rows, 1, 2)).is_false()
	assert_bool(RoomTerrain.is_solid(rows, 0, 0)).is_true()


func test_earth_surface_and_fill_selection() -> void:
	var rows: Array[String] = RoomTerrain.parse_rows("....\nGGGG\nGGGG")
	# 위가 비면 표면 행(0행 0~3열), 막히면 속(4~7열)
	var top: Vector2i = RoomTerrain.atlas_for(rows, 1, 1)
	assert_int(top.y).is_equal(0)
	assert_bool(top.x <= 3).is_true()
	var fill: Vector2i = RoomTerrain.atlas_for(rows, 1, 2)
	assert_bool(fill.x >= 4).is_true()


func test_earth_corners() -> void:
	var rows: Array[String] = RoomTerrain.parse_rows("GGG")
	assert_that(RoomTerrain.atlas_for(rows, 0, 0)).is_equal(Vector2i(2, 0))
	assert_that(RoomTerrain.atlas_for(rows, 2, 0)).is_equal(Vector2i(3, 0))


func test_slope_tiles() -> void:
	var rows: Array[String] = RoomTerrain.parse_rows("/RR\\")
	assert_that(RoomTerrain.atlas_for(rows, 0, 0)).is_equal(Vector2i(6, 3))
	assert_that(RoomTerrain.atlas_for(rows, 3, 0)).is_equal(Vector2i(7, 3))


func test_roof_ridge_and_fill() -> void:
	var rows: Array[String] = RoomTerrain.parse_rows(".RR.\n.RR.")
	assert_that(RoomTerrain.atlas_for(rows, 1, 0)).is_equal(Vector2i(1, 3))
	assert_that(RoomTerrain.atlas_for(rows, 2, 0)).is_equal(Vector2i(2, 3))
	assert_that(RoomTerrain.atlas_for(rows, 1, 1)).is_equal(Vector2i(4, 3))


func test_deck_strip_ends() -> void:
	var rows: Array[String] = RoomTerrain.parse_rows("===.~")
	assert_that(RoomTerrain.atlas_for(rows, 0, 0)).is_equal(Vector2i(0, 4))
	assert_that(RoomTerrain.atlas_for(rows, 1, 0)).is_equal(Vector2i(1, 4))
	assert_that(RoomTerrain.atlas_for(rows, 2, 0)).is_equal(Vector2i(2, 4))
	assert_that(RoomTerrain.atlas_for(rows, 4, 0)).is_equal(Vector2i(3, 5))


func test_empty_cell_has_no_tile() -> void:
	var rows: Array[String] = RoomTerrain.parse_rows(SAMPLE)
	assert_that(RoomTerrain.atlas_for(rows, 1, 1)).is_equal(RoomTerrain.NO_TILE)


func test_unknown_symbols_detected() -> void:
	var rows: Array[String] = RoomTerrain.parse_rows("G?X")
	var bad: Array[String] = RoomTerrain.unknown_symbols(rows)
	assert_int(bad.size()).is_equal(2)
	assert_bool(bad.has("?")).is_true()
	assert_bool(bad.has("X")).is_true()


func test_cells_of_finds_symbols() -> void:
	var rows: Array[String] = RoomTerrain.parse_rows("G.=\n..=")
	var decks: Array[Vector2i] = RoomTerrain.cells_of(rows, "=")
	assert_int(decks.size()).is_equal(2)
	assert_that(decks[0]).is_equal(Vector2i(2, 0))
	assert_that(decks[1]).is_equal(Vector2i(2, 1))


## 장식 심볼 (기둥, 서까래)은 지형으로 세지 않는다. 통행과 도달 가능성에 영향이 없어야 한다
func test_decor_symbols_are_not_solid() -> void:
	var rows: Array[String] = RoomTerrain.parse_rows("=|-\nG..")
	assert_bool(RoomTerrain.is_solid(rows, 1, 0)).is_false()
	assert_bool(RoomTerrain.is_solid(rows, 2, 0)).is_false()
	assert_bool(RoomTerrain.unknown_symbols(rows).is_empty()).is_true()


## 기둥은 위아래 이웃으로 상단, 몸통, 밑동을 고른다
func test_post_picks_top_body_and_base() -> void:
	var rows: Array[String] = RoomTerrain.parse_rows("====\n|...\n|...\nGGGG")
	assert_that(RoomTerrain.atlas_for(rows, 0, 1)).is_equal(Vector2i(0, 6))
	assert_that(RoomTerrain.atlas_for(rows, 0, 2)).is_equal(Vector2i(2, 6))
	var tall: Array[String] = RoomTerrain.parse_rows("R...\n|...\n|...\n|...\nGGGG")
	assert_that(RoomTerrain.atlas_for(tall, 0, 1)).is_equal(Vector2i(0, 6))
	assert_that(RoomTerrain.atlas_for(tall, 0, 2)).is_equal(Vector2i(1, 6))
	assert_that(RoomTerrain.atlas_for(tall, 0, 3)).is_equal(Vector2i(2, 6))


func test_rafter_uses_fixed_tile() -> void:
	var rows: Array[String] = RoomTerrain.parse_rows("RRR\n---")
	assert_that(RoomTerrain.atlas_for(rows, 1, 1)).is_equal(Vector2i(3, 6))
