class_name Minigame
extends Control

## 미니게임 공통 뼈대 (docs/act1/EVENTS.md 3장 발동, 10.2 방 진입과 결과 연출).
##
## 이벤트 노드와 내기방이 방 위에 띄우는 전체 화면 오버레이다. 열려 있는 동안 트리는
## 일시정지 상태이고 미니게임만 process_mode ALWAYS로 돈다. 끝나면 결과 사전을 올려보낸다.
##
## 결과 사전 규격 (호스트와 run_stage가 이 키만 읽는다)
## - won: bool                            성사 여부
## - coins_delta: int                     노잣돈 증감. run_stage가 RunState에 반영한다
## - damage: int                          잃는 체력
## - relic_chance: float                  떨이 유물 추첨 확률
## - title: String                        결과 팝업 제목
## - gains, losses: PackedStringArray     획득과 손실 문구
##
## 색 채널 (docs/act1/EVENTS.md 10.1, DESIGN_ACT1 2장)
## 이득과 플레이어 쪽은 등불 호박, 손실과 상대 쪽은 남색과 회색을 쓴다.
## 적색은 생기 몰림 전용, 청록은 도깨비불과 비밀 신호 전용이라 여기서 쓰지 않는다.

signal finished(result: Dictionary)

## 어두운 배경 막
const BACKDROP: Color = Color(0.05, 0.05, 0.09, 0.90)
## 본문 글자
const INK: Color = Color(0.90, 0.87, 0.80)
## 흐린 글자와 안내
const INK_DIM: Color = Color(0.60, 0.58, 0.54)
## 등불 호박. 플레이어와 이득 신호
const LANTERN: Color = Color(0.92, 0.66, 0.28)
## 남색. 상대와 손실 신호
const NIGHT: Color = Color(0.26, 0.29, 0.48)
## 회색. 남색과 짝지어 쓰는 보조 손실 신호
const NIGHT_DIM: Color = Color(0.46, 0.46, 0.49)
## 기본 글자 크기 (ui/theme/pixel_ui.tres의 galmuri9 기준)
const FONT_SIZE: int = 9
## 강조 글자 크기
const FONT_SIZE_BIG: int = 18


## 결과 사전의 기본값. 하위 클래스는 필요한 항목만 덮어쓴다.
static func empty_result(result_title: String = "") -> Dictionary:
	return {
		"won": false,
		"coins_delta": 0,
		"damage": 0,
		"relic_chance": 0.0,
		"title": result_title,
		"gains": PackedStringArray(),
		"losses": PackedStringArray(),
	}


## 호스트가 트리에 붙인 뒤 부른다. config는 seed와 coins 등 시작 조건이다.
func begin(_config: Dictionary) -> void:
	push_warning("begin을 구현하지 않은 미니게임이다")


## 결과를 알리고 닫는다. 하위 클래스가 끝날 때 부른다.
func report(result: Dictionary) -> void:
	set_process(false)
	set_process_input(false)
	finished.emit(result)


func body_font() -> Font:
	return get_theme_default_font()


## 화면 가로 가운데에 글자를 그린다. y는 글자 밑선이다.
func draw_center(text: String, y: float, font_size: int, color: Color) -> void:
	var font: Font = body_font()
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	draw_string(
		font,
		Vector2(size.x * 0.5 - width * 0.5, y),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		color
	)


## 테두리를 두른 막대. 채운 비율만 색을 넣는다.
func draw_meter(box: Rect2, ratio: float, fill: Color, back: Color) -> void:
	draw_rect(box, back)
	var width: float = box.size.x * clampf(ratio, 0.0, 1.0)
	draw_rect(Rect2(box.position, Vector2(width, box.size.y)), fill)
	draw_rect(box, INK_DIM, false, 1.0)
