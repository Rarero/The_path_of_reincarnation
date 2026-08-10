extends Control

## 오프닝 컷신 (intro).
##
## 정적 일러스트 미국 컷툰 연출. 페이지 데이터를 순서대로 재생한다.
## 3페이지(트럭 충돌) 끝에서 화이트 플래시로 전환한다. 스킵은 ui_cancel.
## docs/DESIGN_INTRO.md 4장.

const FLASH_IN: float = 0.35
const FLASH_HOLD: float = 0.1
const FLASH_OUT: float = 0.5

## 페이지 스키마: id, art(패널 설명 플레이스홀더), lines(캡션과 대사), flash_after
const PAGES: Array[Dictionary] = [
	{
		"id": "office",
		"tex": "res://assets/sprites/intro/intro_p1_office.png",
		"art": "패널: 야심한 사무실에 홀로 남은 주인공, 이어서 텅 빈 밤거리로 나오는 뒷모습",
		"lines": ["또 막차 시간이다.", "독백: 사무실 불은 오늘도 내가 껐다. 집에 가서 눕기만 하면 돼."],
		"flash_after": false,
	},
	{
		"id": "crosswalk",
		"tex": "res://assets/sprites/intro/intro_p2_crosswalk.png",
		"art": "패널: 신호를 기다리는 주인공, 신호가 초록으로. 뒤에서 말풍선 세 개가 점점 크게",
		"lines": ["뒤에서 누가 부른다.", "목소리: OO아... OO아... OO아...", "독백: 누가 내 이름을."],
		"flash_after": false,
	},
	{
		"id": "truck",
		"tex": "res://assets/sprites/intro/intro_p3_truck.png",
		"art": "패널: 뒤돌아보는 얼굴 클로즈업, 이어서 측면에서 쏟아지는 트럭 헤드라이트",
		"lines": ["뒤를 돌아본 순간.", "빵—"],
		"flash_after": true,
	},
	{
		"id": "saja",
		"tex": "res://assets/sprites/intro/intro_p4_saja.png",
		"art": "패널: 눈을 뜨는 시야, 검은 갓과 검은 두루마기의 저승사자가 머리를 짚고 내려다본다",
		"lines": ["눈을 뜨니 낯선 천장.", "차사: 어어, 깼네.", "차사: ...어, 잠깐."],
		"flash_after": false,
	},
	{
		"id": "mistake",
		"tex": "res://assets/sprites/intro/intro_p5_mistake.png",
		"art": "패널: 차사가 손에 든 문서를 보며 동명이인임을 알고 곤란해하는 표정 (p4 시점 연장)",
		"lines": ["차사: 김... 아니 이...? 동명이인이네.", "차사: 자네, 아직 죽을 때가 아니야.", "잘못 데려온 것이다."],
		"flash_after": false,
	},
	{
		"id": "queue",
		"tex": "res://assets/sprites/intro/intro_p6_queue.png",
		"art": "패널: 끝없는 민원 대기줄과 번호표, 먼지 쌓인 특수창고 팻말",
		"lines":
		[
			"여기서부터 약 300년 소요.",
			"차사: 돌아가려면 반송 도장이 필요한데, 대기가 좀 있어.",
			"차사: 원래 삼백 년인데 자넨 특수창고라 오십 년만 기다리면 돼.",
			"주인공: 오십 년을 어떻게 기다려.",
		],
		"flash_after": false,
	},
	{
		"id": "resolve",
		"tex": "res://assets/sprites/intro/intro_p7_resolve.png",
		"art": "패널: 접수청 안쪽 위로 뻗은 길과 멀리 염라대전 실루엣, 소매 걷고 돌아서는 뒷모습",
		"lines": ["주인공: 직접 가서 도장 받아 오면 되잖아.", "차사: 거긴 함부로 가는 데가—", "염라를 만나러."],
		"flash_after": false,
	},
]

var _page: int = 0
var _line: int = 0
var _busy: bool = false
var _done: bool = false

@onready var art_image: TextureRect = %ArtImage
@onready var caption_label: Label = %CaptionLabel
@onready var flash: ColorRect = %Flash


func _ready() -> void:
	AudioDirector.play_bgm(AudioDirector.Track.INTRO)
	flash.color = Color(1, 1, 1, 0)
	_show_page(0)


func _unhandled_input(event: InputEvent) -> void:
	if _done or _busy:
		return
	if event.is_action_pressed(&"ui_cancel"):
		_finish()
		return
	if event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"move_up"):
		_advance()


func _advance() -> void:
	var page: Dictionary = PAGES[_page]
	var lines: Array = page["lines"]
	if _line + 1 < lines.size():
		_line += 1
		_show_line()
		return
	_go_next_page(page)


func _go_next_page(page: Dictionary) -> void:
	if _page + 1 >= PAGES.size():
		_finish()
		return
	_busy = true
	if bool(page.get("flash_after", false)):
		await _flash_to(1.0, FLASH_IN)
		await get_tree().create_timer(FLASH_HOLD).timeout
		_show_page(_page + 1)
		await _flash_to(0.0, FLASH_OUT)
	else:
		_show_page(_page + 1)
	_busy = false


func _show_page(index: int) -> void:
	_page = index
	_line = 0
	var tex_path: String = str(PAGES[index].get("tex", ""))
	if tex_path != "" and ResourceLoader.exists(tex_path):
		art_image.texture = load(tex_path)
	else:
		art_image.texture = null
	_show_line()


func _show_line() -> void:
	var lines: Array = PAGES[_page]["lines"]
	if lines.is_empty():
		caption_label.text = ""
		return
	caption_label.text = str(lines[_line])


func _flash_to(target_alpha: float, time: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(flash, "color:a", target_alpha, time)
	# gdlint:ignore=expression-not-assigned
	await tween.finished


func _finish() -> void:
	if _done:
		return
	_done = true
	GameState.intro_seen = true
	SceneRouter.goto_hub()
