class_name BgAct1
extends ParallaxBackground

## 1막 배경 랜덤 조합기 (docs/DECISIONS.md 2026-08-04 배경 방 단위 랜덤 조합).
##
## 원경(하늘 채움, 별, 달, 스카이라인, 등불 줄)은 고정 레이어로 두고,
## 중경/근경 조각(가판대, 주막, 귀문, 씨름판, 노름판, 군상, 도깨비불)을
## 시드 기반으로 재조합한다. run_stage가 방 로드마다 rebuild를 호출한다.
## 단독 사용(stage_act1_rough, stage_verify 등)에서는 _ready에서 무작위 시드로 1회 조합한다.
##
## 배치 규칙 (2026-08-04 디렉팅):
## - 접지선(조각 바닥 y)은 고정, 가로 위치만 랜덤
## - 레이어별 최소 간격(min_gap)으로 구조물 겹침 금지
## - 동일 조각은 최소 이격 거리(same_min_dist) 미만으로 붙지 않는다
## - 인접 조각의 궁합(AFFINITY) 점수로 후보 배치 중 최고점을 채택한다
##
## 조명 규칙 (2026-08-05 청사초롱 광원 디렉팅, DESIGN_ACT1 2.5):
## - 밝기는 전역 상향이 아니라 광원에서 나온다. 레이어 침전값은 난색 틴트만 담당한다
## - 등불과 도깨비불은 PointLight2D. 반드시 _make_light로 만들어 레이어 범위를 넣는다
## - 바닥 빛 웅덩이와 거리 훈기는 가산 합성 스프라이트 (미러링 복제와 광원 수 절약)
##
## 밀도 규칙 (2026-08-05 배경 밀도 보강, ART_STYLE 5장):
## - 하늘과 원경을 비워 두지 않는다. 밤구름(L0)과 절차 능선(L0Ridge)이 빈 띠를 채운다
## - 거리 등불(라이트 + 바닥 빛 웅덩이 쌍)이 좌판 사이를 밝혀 활기를 만든다
## - 밀도의 재료는 픽셀 디테일이 아니라 레이어 겹침과 대기 효과다 (불똥, 훈기)
##
## 군상 규칙 (2026-08-05 복작복작 디렉팅):
## - 정면/뒷모습/환호/특수(아이, 고양이)를 섞는다. 정면 일색 금지
## - 씨름판 대전 한 쌍, 노름판 둘러앉기, 좌판 앞 손님으로 활동 장면을 만든다

## 중경/근경 조합 스트립 폭. 두 레이어의 motion_mirroring x와 일치해야 한다
const STRIP_WIDTH: float = 1024.0
## 배경 프리셋. 신당처럼 랜드마크가 방의 의미를 만드는 방은 랜덤 조합을 끈다
## (요청서 022 E절, DECISIONS 2026-08-05 결정 6).
enum Preset { STREET, SHRINE_ALLEY, SHRINE_SEONANG }

## 프리셋 이름(Room.bg_preset 문자열) -> Preset 대응
const PRESET_BY_NAME: Dictionary = {
	"street": Preset.STREET,
	"shrine_alley": Preset.SHRINE_ALLEY,
	"shrine_seonang": Preset.SHRINE_SEONANG,
}

## 신당 방의 난색 공백 구간 (요청서 022 E-2-2). 이 구간에는 좌판도 등불도 두지 않는다.
## 서낭당은 좌우로 거리가 이어지다 신목 앞에서만 색이 빠져야 대비가 성립한다
const SHRINE_VOID_MIN: float = 120.0
const SHRINE_VOID_MAX: float = 360.0
## 공백 판정 시 조각 폭을 모를 때 쓰는 여유 (px)
const SHRINE_VOID_MARGIN: float = 24.0
## 신당 바닥 안개. 거리의 난색 훈기(HAZE_COLOR)와 달리 한색이라 공기가 서늘해진다
const SHRINE_MIST_COLOR: Color = Color(0.62, 0.70, 0.92)
const SHRINE_MIST_COUNT: int = 5
const SHRINE_MIST_ALPHA: float = 0.09
const SHRINE_MIST_Y: float = 326.0

## 골목 사당 중경의 창 불빛 수 (DESIGN_ACT1 2.7 골목 L2 = 반대편 벽면, 창 불빛)
const ALLEY_WINDOW_COUNT: int = 5

## 좌판 거리 기본 근경 침전값 (bg_act1.tscn L3Near modulate와 같아야 한다)
const STREET_NEAR_MODULATE: Color = Color(0.8, 0.71, 0.6, 1)
## 골목 사당은 저조도라 근경을 한 단 더 누른다 (DESIGN_ACT1 2.7 골목 테마)
const ALLEY_NEAR_MODULATE: Color = Color(0.44, 0.41, 0.52, 1)

## 배치 후보 수. 후보마다 궁합 점수를 매겨 최고점을 쓴다
const LAYOUT_CANDIDATES: int = 12
## 이 간격(px) 이하로 이웃한 두 조각을 "옆"으로 보고 궁합 점수를 적용한다
const NEIGHBOR_DIST: float = 48.0
## 동일 조각 최소 이격 위반 시 감점 (사실상 배제용 큰 값)
const SAME_TOO_CLOSE_PENALTY: float = 100.0

## 레이어별 구조물 최소 간격 (px)
const MID_MIN_GAP: float = 8.0
const NEAR_MIN_GAP: float = 12.0
## 레이어별 동일 조각 최소 이격 거리 (좌단 기준 px).
## 2026-08-05 하향: 120/160은 배치 단계에서 요청 개수를 잘라 먹어 거리가 휑해지던
## 실제 원인이었다. 같은 좌판이 스트립당 3~4개 서려면 이 값이 절반 이하여야 한다
const MID_SAME_MIN_DIST: float = 64.0
const NEAR_SAME_MIN_DIST: float = 96.0

## 군상 분산 규칙 (2026-08-04 쏠림 교정): 앵커 순환 배정 + 최소 간격 + 행인
## 군상이 앵커 없이 거리를 걷는 행인이 될 확률
const CROWD_STROLL_CHANCE: float = 0.3
## 군상 간 최소 가로 간격 (px). 위반 시 재추첨 (최대 CROWD_RETRIES회)
const CROWD_MIN_DIST: float = 14.0
const CROWD_RETRIES: int = 6

## 구조물 등불 (환한 야시장 분위기, 2026-08-04 분위기 반전)
const WARM_GLOW_COLOR: Color = Color(1.0, 0.745, 0.431)
const NEAR_GLOW_CHANCE: float = 1.0
const MID_GLOW_CHANCE: float = 0.9

## 배경 광원 레이어 범위 (2026-08-05 조명 수정).
## ParallaxBackground는 CanvasLayer layer = -100이고 Light2D 기본 범위는 0~0이라,
## 기본값 그대로면 배경 캔버스가 광원 대상에서 컬링돼 아무것도 비추지 못한다.
## 배경에서 만드는 모든 광원은 _make_light를 거쳐 이 범위를 갖는다
const LIGHT_LAYER_MIN: int = -256
const LIGHT_LAYER_MAX: int = 256

## 바닥 빛 웅덩이 (청사초롱 빛이 거리 바닥에 만드는 타원 빛무리, DESIGN_ACT1 2.5).
## 광원이 아니라 가산 합성 스프라이트다. 패럴랙스 미러링은 스프라이트만 복제하므로
## 스트립이 반복돼도 웅덩이가 함께 반복되고, 레이어당 광원 수 상한도 아낀다
const POOL_COLOR: Color = Color(1.0, 0.784, 0.51)
## 빛 웅덩이 중심 y (근경 거리 바닥)
const POOL_BOTTOM: float = 331.0
const POOL_ALPHA_MIN: float = 0.26
const POOL_ALPHA_MAX: float = 0.42

## 거리 훈기. 시장 전체를 덮는 옅은 난색 대기층 (왁자지껄한 온기)
const HAZE_COLOR: Color = Color(1.0, 0.62, 0.33)
const HAZE_COUNT: int = 4
const HAZE_ALPHA: float = 0.07
const HAZE_Y: float = 300.0

## 거리 등불 (2026-08-05 밝기 상향). 시장 중간 중간의 독립 광원.
## 라이트와 바닥 빛 웅덩이를 쌍으로 깔아 좌판 사이 어두운 구간을 없앤다.
## 간격은 5~7타일 (DESIGN_ACT1 3.4 구조물 리듬과 동율)
const STREET_LIGHT_STEP_MIN: float = 80.0
const STREET_LIGHT_STEP_MAX: float = 112.0
const STREET_LIGHT_Y: float = 300.0
const STREET_LIGHT_ENERGY_MIN: float = 0.42
const STREET_LIGHT_ENERGY_MAX: float = 0.58

## 밤구름 (2026-08-05 밀도 보강. DESIGN_ACT1 2.3 L0 "옅은 구름").
## 고정 시드로 1회 생성한다. 원경이라 방마다 바뀌지 않는다
const CLOUD_SEED: int = 20260805
const CLOUD_COLOR: Color = Color(0.145, 0.141, 0.298)
const CLOUD_COUNT: int = 13
const CLOUD_ALPHA_MIN: float = 0.35
const CLOUD_ALPHA_MAX: float = 0.62
const CLOUD_Y_MIN: float = -44.0
const CLOUD_Y_MAX: float = 205.0

## 원경 능선 (DESIGN_ACT1 2.3 L1 "시장 너머 능선"). 절차 생성 실루엣 2겹.
## 파형 개수는 정수라 스트립 폭에서 이어진다 (미러링 이음새 방지)
const RIDGE_WIDTH: int = 512
const RIDGE_HEIGHT: int = 104
## 능선 바닥 y. 스카이라인 밴드(246~292) 뒤에 깔린다
const RIDGE_BOTTOM: float = 298.0
const RIDGE_BACK_COLOR: Color = Color(0.118, 0.11, 0.204)
const RIDGE_FRONT_COLOR: Color = Color(0.086, 0.078, 0.149)

## 불똥 (ART_STYLE 5장 대기 파티클). 가산 합성 스프라이트가 천천히 떠오른다
const EMBER_SCRIPT: Script = preload("res://scripts/bg/ember_drift.gd")
const EMBER_COLOR: Color = Color(1.0, 0.678, 0.353)
const EMBER_MID_COUNT: int = 10
const EMBER_NEAR_COUNT: int = 14
const EMBER_TOP_Y: float = 176.0
const EMBER_BOTTOM_Y: float = 336.0

## 신기 티끌 (요청서 022 E-2 신비감 보강). 랜드마크 앞 난색 공백에만 띄운다.
## 거리 불똥과 색(한색)과 속도(3분의 1)로 갈라야 "불티"가 아니라 "신기"로 읽힌다.
## 공백 밖에 두면 불똥과 섞여 그냥 먼지가 되므로 x는 반드시 공백 대역 안이다
const SPIRIT_MOTE_SCRIPT: Script = preload("res://scripts/bg/spirit_mote.gd")
const SPIRIT_MOTE_COLOR: Color = Color(0.78, 0.84, 0.95)
const SPIRIT_MOTE_COUNT: int = 7
const SPIRIT_MOTE_TOP_Y: float = 150.0
const SPIRIT_MOTE_BOTTOM_Y: float = 336.0

## 별 배치용 고정 시드. 원경은 방마다 바뀌지 않는다
const STAR_SEED: int = 20260804
## 원경 별 개수 (미러 주기 512 스트립 기준)
const STAR_COUNT: int = 44
## 별 세로 분포 구간 (카메라 상승 시 노출되는 상단 하늘까지 채운다)
const STAR_Y_MIN: float = -72.0
const STAR_Y_MAX: float = 210.0

const CROWD_SCRIPT: Script = preload("res://scripts/bg/crowd_figure.gd")
const LANTERN_SCRIPT: Script = preload("res://scripts/bg/lantern_light.gd")
const GLOW_TEXTURE: Texture2D = preload("res://assets/sprites/fx/glow_radial_64.png")
## 도깨비불 색. 청록 채널 (DESIGN_ACT1 색 채널 규약: 청록 = 도깨비불)
const DOKKAEBI_FIRE_COLOR: Color = Color(0.353, 0.863, 0.784)

## 중경 구조물 풀. name 궁합 키, tex 텍스처, bottom 접지선 y,
## max 스트립당 최대 개수, crowd 군상 유인 가중치
const MID_PROPS: Array[Dictionary] = [
	{
		"name": "stall_mid_a",
		"tex": preload("res://assets/sprites/bg/act1/bg_stall_mid_a.png"),
		"bottom": 312.0,
		"max": 4,
		"crowd": 2,
	},
	{
		"name": "stall_mid_b",
		"tex": preload("res://assets/sprites/bg/act1/bg_stall_mid_b.png"),
		"bottom": 312.0,
		"max": 4,
		"crowd": 2,
	},
	{
		"name": "stall_mid_c",
		"tex": preload("res://assets/sprites/bg/act1/bg_stall_mid_c.png"),
		"bottom": 312.0,
		"max": 4,
		"crowd": 2,
	},
	{
		"name": "tavern_mid",
		"tex": preload("res://assets/sprites/bg/act1/bg_tavern_mid.png"),
		"bottom": 312.0,
		"max": 1,
		"crowd": 2,
	},
]

## 근경 구조물 풀. bottom 값은 기존 수동 배치에서 검증된 접지선을 데이터화한 것
const NEAR_PROPS: Array[Dictionary] = [
	{
		"name": "gate",
		"tex": preload("res://assets/sprites/bg/act1/bg_gwimun_gate.png"),
		"bottom": 326.0,
		"max": 1,
		"crowd": 1,
	},
	{
		"name": "tavern",
		"tex": preload("res://assets/sprites/bg/act1/bg_tavern.png"),
		"bottom": 328.0,
		"max": 1,
		"crowd": 2,
	},
	{
		"name": "stall_fruit",
		"tex": preload("res://assets/sprites/bg/act1/bg_stall_fruit.png"),
		"bottom": 330.0,
		"max": 4,
		"crowd": 2,
	},
	{
		"name": "ring",
		"tex": preload("res://assets/sprites/bg/act1/bg_ssireum_ring.png"),
		"bottom": 332.0,
		"max": 1,
		"crowd": 3,
	},
	{
		"name": "mat",
		"tex": preload("res://assets/sprites/bg/act1/bg_gambling_mat.png"),
		"bottom": 332.0,
		"max": 4,
		"crowd": 3,
	},
]

## 인접 궁합표. 키는 _pair_key(이름 정렬 조인), 값이 클수록 어울린다.
## 주막 곁 저자와 노름판은 +, 귀문(신성한 경계)은 세속 조각과 붙으면 -.
## 표에 없는 쌍은 0 (무관).
const MID_AFFINITY: Dictionary = {
	"stall_mid_a|stall_mid_b": 1.0,
	"stall_mid_a|stall_mid_c": 1.0,
	"stall_mid_b|stall_mid_c": 1.0,
	"stall_mid_a|tavern_mid": 1.0,
	"stall_mid_b|tavern_mid": 1.0,
	"stall_mid_c|tavern_mid": 1.0,
}
const NEAR_AFFINITY: Dictionary = {
	"stall_fruit|tavern": 2.0,
	"mat|tavern": 2.0,
	"mat|ring": 1.0,
	"mat|stall_fruit": 1.0,
	"gate|tavern": -2.0,
	"gate|mat": -3.0,
	"gate|ring": -1.0,
	"gate|stall_fruit": -1.0,
}

## 군상 텍스처 풀 (중경/근경 공용. 접지선만 레이어별로 다르다).
## 2026-08-05 재편: 정면 일색 교정. 요청서 012 그리드에서 뒷모습, 환호, 아이,
## 고양이를 추가 수확했다 (tools/pipeline/bake_crowd_variants.py).
## crowd_b는 원래 뒷모습이라 뒷모습 풀로 옮겼다
const CROWD_FRONT_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/bg/act1/crowd/crowd_a.png"),
	preload("res://assets/sprites/bg/act1/crowd/crowd_c.png"),
	preload("res://assets/sprites/bg/act1/crowd/crowd_d.png"),
	preload("res://assets/sprites/bg/act1/crowd/crowd_e.png"),
	preload("res://assets/sprites/bg/act1/crowd/crowd_f.png"),
	preload("res://assets/sprites/bg/act1/crowd/crowd_g.png"),
	preload("res://assets/sprites/bg/act1/crowd/crowd_h.png"),
]
const CROWD_BACK_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/bg/act1/crowd/crowd_b.png"),
	preload("res://assets/sprites/bg/act1/crowd/crowd_back_a.png"),
	preload("res://assets/sprites/bg/act1/crowd/crowd_back_b.png"),
	preload("res://assets/sprites/bg/act1/crowd/crowd_back_c.png"),
	preload("res://assets/sprites/bg/act1/crowd/crowd_back_d.png"),
	preload("res://assets/sprites/bg/act1/crowd/crowd_back_e.png"),
]
## 팔을 든 환호 자세. 씨름판과 노름판 구경꾼 전용
const CROWD_CHEER_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/bg/act1/crowd/crowd_cheer_a.png"),
	preload("res://assets/sprites/bg/act1/crowd/crowd_cheer_b.png"),
]
## 씨름꾼은 소품 없는 맨손 정면 2종만 쓴다
const CROWD_WRESTLER_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/bg/act1/crowd/crowd_g.png"),
	preload("res://assets/sprites/bg/act1/crowd/crowd_h.png"),
]
## 행인 다양화용 특수 (아이, 저자 고양이). 낮은 확률로만 섞는다
const CROWD_EXTRA_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/bg/act1/crowd/crowd_child.png"),
	preload("res://assets/sprites/bg/act1/crowd/crowd_cat.png"),
]
## 행인 텍스처 추첨 확률 (특수 / 뒷모습. 나머지는 정면)
const CROWD_EXTRA_CHANCE: float = 0.1
const CROWD_BACK_CHANCE: float = 0.28
## 활동을 벌이는 노름판 수 상한 (전부 벌이면 소란이 균질해진다)
const ACTIVITY_MAT_MAX: int = 2

## 군상 접지선 (기존 수동 배치 기준: 중경 310, 근경 332)
const MID_CROWD_BOTTOM: float = 310.0
const NEAR_CROWD_BOTTOM: float = 332.0

var _built: bool = false
## 빛 웅덩이와 훈기가 공유하는 가산 합성 머티리얼. 첫 사용 시 만든다
var _glow_material: CanvasItemMaterial = null

@onready var _stars: Node2D = $L0Sky/Stars as Node2D
@onready var _clouds: Node2D = $L0Sky/Clouds as Node2D
@onready var _ridges: Node2D = $L0Ridge/Ridges as Node2D
@onready var _mid_gen: Node2D = $L2Mid/Gen as Node2D
@onready var _near_gen: Node2D = $L3Near/Gen as Node2D


func _ready() -> void:
	_build_stars()
	_build_clouds()
	_build_ridges()
	if not _built:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.randomize()
		rebuild(int(rng.randi()))


## 시드로 중경/근경을 재조합한다. 같은 시드는 같은 배경을 만든다 (이어하기 재현).
func rebuild(seed_value: int, preset: int = Preset.STREET) -> void:
	_built = true
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	_clear_generated(_mid_gen)
	_clear_generated(_near_gen)
	_apply_preset(preset)
	if preset != Preset.STREET:
		_build_shrine_backdrop(preset, rng)
		return
	var mid_placed: Array[Dictionary] = _spawn_props(
		_mid_gen,
		MID_PROPS,
		rng.randi_range(9, 11),
		MID_MIN_GAP,
		MID_SAME_MIN_DIST,
		MID_AFFINITY,
		rng
	)
	_spawn_prop_glows(_mid_gen, mid_placed, MID_GLOW_CHANCE, 0.52, 1.1, rng)
	var mid_busy: Array[float] = _spawn_mid_customers(_mid_gen, mid_placed, rng)
	_spawn_crowd(_mid_gen, mid_placed, rng.randi_range(8, 10), MID_CROWD_BOTTOM, rng, mid_busy)
	var near_placed: Array[Dictionary] = _spawn_props(
		_near_gen,
		NEAR_PROPS,
		rng.randi_range(8, 10),
		NEAR_MIN_GAP,
		NEAR_SAME_MIN_DIST,
		NEAR_AFFINITY,
		rng
	)
	_spawn_prop_glows(_near_gen, near_placed, NEAR_GLOW_CHANCE, 0.66, 1.2, rng)
	var near_busy: Array[float] = _spawn_activities(_near_gen, near_placed, rng)
	_spawn_crowd(_near_gen, near_placed, rng.randi_range(9, 12), NEAR_CROWD_BOTTOM, rng, near_busy)
	_spawn_fires(_near_gen, rng.randi_range(2, 3), rng)
	_spawn_haze(_mid_gen, rng)
	_spawn_street_lights(_near_gen, rng)
	_spawn_embers(_mid_gen, EMBER_MID_COUNT, 0.7, rng)
	_spawn_embers(_near_gen, EMBER_NEAR_COUNT, 1.0, rng)


## 신당 방 배경. 방의 의미를 만드는 조각은 방 씬이 직접 놓지만, 대기까지 비우면
## 화면이 휑해진다 (ART_STYLE 5장 "배경을 비워 두지 않는다"). 구조물만 걷어내고
## 안개, 불똥, 좌우 거리는 남긴다.
func _build_shrine_backdrop(preset: int, rng: RandomNumberGenerator) -> void:
	if preset == Preset.SHRINE_SEONANG:
		# 좌판 거리가 좌우로 이어지고 신목 앞에서만 난색이 빠진다 (요청서 022 E-2-2).
		# 거리 자체가 없으면 "밝은 거리 속의 서늘한 공백"이라는 대비가 성립하지 않는다
		var mid_placed: Array[Dictionary] = _spawn_props(
			_mid_gen,
			MID_PROPS,
			rng.randi_range(7, 9),
			MID_MIN_GAP,
			MID_SAME_MIN_DIST,
			MID_AFFINITY,
			rng
		)
		_spawn_prop_glows(_mid_gen, mid_placed, MID_GLOW_CHANCE, 0.52, 1.1, rng)
		_spawn_crowd(_mid_gen, mid_placed, rng.randi_range(5, 7), MID_CROWD_BOTTOM, rng, [])
		_spawn_street_lights(_near_gen, rng)
		_clear_void_band(_mid_gen)
		_clear_void_band(_near_gen)
	else:
		# 골목은 좌판이 없다. 반대편 벽면의 창 불빛만 점점이 둔다 (DESIGN_ACT1 2.7)
		_spawn_alley_windows(_mid_gen, rng)
	if preset == Preset.SHRINE_SEONANG:
		_spawn_haze(_mid_gen, rng)
	_spawn_shrine_mist(_near_gen, rng)
	_spawn_embers(_mid_gen, EMBER_MID_COUNT / 2, 0.55, rng)
	_spawn_spirit_motes(_near_gen, rng)


## 신당 바닥에 낮게 깔린 한색 안개. 거리의 난색 훈기와 색온도를 갈라
## 같은 밤인데 공기만 서늘해 보이게 만든다.
func _spawn_shrine_mist(parent: Node2D, rng: RandomNumberGenerator) -> void:
	var step: float = STRIP_WIDTH / float(SHRINE_MIST_COUNT)
	for i: int in range(SHRINE_MIST_COUNT):
		var mist: Sprite2D = Sprite2D.new()
		mist.texture = GLOW_TEXTURE
		mist.material = _ensure_glow_material()
		mist.position = Vector2(
			step * (float(i) + 0.5) + rng.randf_range(-24.0, 24.0),
			SHRINE_MIST_Y + rng.randf_range(-4.0, 4.0)
		)
		mist.scale = Vector2(rng.randf_range(4.0, 6.0), rng.randf_range(0.5, 0.8))
		mist.modulate = Color(SHRINE_MIST_COLOR, SHRINE_MIST_ALPHA * rng.randf_range(0.7, 1.3))
		parent.add_child(mist)


## 랜드마크 앞 공백에 신기 티끌을 띄운다. 알파 호흡으로 나타났다 사라지는 것이
## 신비한 인상의 핵심이라 개체마다 주기와 위상을 흩는다 (동시 점멸은 UI로 읽힌다).
func _spawn_spirit_motes(parent: Node2D, rng: RandomNumberGenerator) -> void:
	var image: Image = Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	image.set_pixel(0, 0, Color.WHITE)
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	for i: int in range(SPIRIT_MOTE_COUNT):
		var mote: Sprite2D = Sprite2D.new()
		mote.centered = false
		mote.texture = texture
		mote.material = _ensure_glow_material()
		mote.position = Vector2(
			rng.randf_range(SHRINE_VOID_MIN + 8.0, SHRINE_VOID_MAX - 8.0),
			rng.randf_range(SPIRIT_MOTE_TOP_Y + 24.0, SPIRIT_MOTE_BOTTOM_Y)
		)
		mote.modulate = Color(SPIRIT_MOTE_COLOR, rng.randf_range(0.4, 0.7))
		mote.set_script(SPIRIT_MOTE_SCRIPT)
		mote.set("rise_speed", rng.randf_range(1.6, 3.0))
		mote.set("top_y", SPIRIT_MOTE_TOP_Y)
		mote.set("bottom_y", SPIRIT_MOTE_BOTTOM_Y)
		mote.set("sway_pixels", rng.randf_range(2.0, 4.0))
		mote.set("fade_period", rng.randf_range(3.5, 5.5))
		parent.add_child(mote)


## 난색 공백 구간에 걸친 배경 자식을 걷어낸다. 조각과 광원을 함께 처리하려고
## 스프라이트는 실제 폭으로, 나머지는 여유값으로 겹침을 본다.
func _clear_void_band(parent: Node2D) -> void:
	for child: Node in parent.get_children():
		var node: Node2D = child as Node2D
		if node == null:
			continue
		var left: float = node.position.x - SHRINE_VOID_MARGIN
		var right: float = node.position.x + SHRINE_VOID_MARGIN
		var sprite: Sprite2D = node as Sprite2D
		if sprite != null and sprite.texture != null:
			var width: float = float(sprite.texture.get_width()) * absf(sprite.scale.x)
			if sprite.centered:
				left = node.position.x - width * 0.5
				right = node.position.x + width * 0.5
			else:
				left = node.position.x
				right = node.position.x + width
		if right > SHRINE_VOID_MIN and left < SHRINE_VOID_MAX:
			node.queue_free()


## 골목 반대편 벽면의 창 불빛. 좌판 없이 중경을 채우는 최소 요소다.
func _spawn_alley_windows(parent: Node2D, rng: RandomNumberGenerator) -> void:
	for i: int in range(ALLEY_WINDOW_COUNT):
		var x: float = STRIP_WIDTH * (float(i) + 0.5) / float(ALLEY_WINDOW_COUNT)
		x += rng.randf_range(-28.0, 28.0)
		var light: PointLight2D = _make_light(
			WARM_GLOW_COLOR, rng.randf_range(0.16, 0.26), rng.randf_range(0.45, 0.7)
		)
		light.position = Vector2(x, MID_CROWD_BOTTOM - rng.randf_range(18.0, 46.0))
		light.set_script(LANTERN_SCRIPT)
		light.set("energy_amount", 0.05)
		light.set("period", rng.randf_range(2.6, 4.2))
		light.set("sway_pixels", 0.0)
		parent.add_child(light)


## 궁합표 키. 이름 두 개를 정렬해 조인한다.
static func pair_key(a: String, b: String) -> String:
	return a + "|" + b if a <= b else b + "|" + a


## 배치 점수. 이웃(간격 neighbor_dist 이하) 쌍에 궁합 점수를 더하고,
## 동일 조각이 same_min_dist 미만으로 붙으면 크게 감점한다.
## placements: [{"name": String, "x": float, "width": float}] (x 오름차순).
static func score_layout(
	placements: Array[Dictionary], affinity: Dictionary, neighbor_dist: float, same_min_dist: float
) -> float:
	var score: float = 0.0
	for i: int in range(placements.size() - 1):
		var left: Dictionary = placements[i]
		var right: Dictionary = placements[i + 1]
		var gap: float = float(right["x"]) - (float(left["x"]) + float(left["width"]))
		if gap <= neighbor_dist:
			score += float(affinity.get(pair_key(String(left["name"]), String(right["name"])), 0.0))
	for i: int in range(placements.size()):
		for j: int in range(i + 1, placements.size()):
			if String(placements[i]["name"]) != String(placements[j]["name"]):
				continue
			if absf(float(placements[j]["x"]) - float(placements[i]["x"])) < same_min_dist:
				score -= SAME_TOO_CLOSE_PENALTY
	return score


## 조각 배치를 뽑는다. 후보를 여러 개 만들어 score_layout 최고점을 반환한다.
## entries: [{"name": String, "width": float, "max": int}]
## 반환: [{"index": int, "name": String, "x": float, "width": float}] (x 오름차순).
## 최소 간격(min_gap)과 동일 조각 이격(same_min_dist)은 하드 제약이다.
## 순수 함수라 단위 테스트 대상이다 (tests/unit/test_bg_act1.gd).
static func plan_layout(
	rng: RandomNumberGenerator,
	entries: Array[Dictionary],
	count: int,
	strip_width: float,
	min_gap: float,
	same_min_dist: float,
	affinity: Dictionary,
	candidates: int
) -> Array[Dictionary]:
	var pool: Array[int] = []
	for i: int in range(entries.size()):
		for c: int in range(int(entries[i]["max"])):
			pool.append(i)
	var best: Array[Dictionary] = []
	var best_score: float = -INF
	for attempt: int in range(candidates):
		var layout: Array[Dictionary] = _sample_layout(
			rng, entries, pool, count, strip_width, min_gap, same_min_dist
		)
		var score: float = score_layout(layout, affinity, NEIGHBOR_DIST, same_min_dist)
		if score > best_score:
			best_score = score
			best = layout
	return best


## 후보 배치 1개를 뽑는다. 남는 폭을 랜덤 틈으로 분할해 고르게 흩되,
## 최소 간격과 동일 조각 이격은 하드 제약이다 (위반 위치는 우측으로 밀고,
## 스트립을 벗어나면 그 조각을 버린다).
static func _sample_layout(
	rng: RandomNumberGenerator,
	entries: Array[Dictionary],
	pool: Array[int],
	count: int,
	strip_width: float,
	min_gap: float,
	same_min_dist: float
) -> Array[Dictionary]:
	var order: Array[int] = pool.duplicate()
	for i: int in range(order.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: int = order[i]
		order[i] = order[j]
		order[j] = swap
	var picked: Array[int] = []
	var total: float = 0.0
	for idx: int in order:
		if picked.size() >= count:
			break
		var width: float = float(entries[idx]["width"])
		var needed_gap: float = min_gap * float(picked.size())
		if total + width + needed_gap > strip_width:
			continue
		picked.append(idx)
		total += width
	var gap_count: int = picked.size() + 1
	var gaps: Array[float] = []
	var gap_total: float = 0.0
	for i: int in range(gap_count):
		var gap: float = rng.randf_range(0.2, 1.0)
		gaps.append(gap)
		gap_total += gap
	var free: float = strip_width - total - min_gap * float(picked.size() - 1)
	var placements: Array[Dictionary] = []
	var planned_x: float = 0.0
	var cursor: float = 0.0
	var last_same: Dictionary = {}
	for i: int in range(picked.size()):
		planned_x += free * gaps[i] / gap_total
		if i > 0:
			planned_x += min_gap
		var idx: int = picked[i]
		var name: String = String(entries[idx]["name"])
		var width: float = float(entries[idx]["width"])
		var x: float = maxf(planned_x, cursor)
		if last_same.has(name):
			x = maxf(x, float(last_same[name]) + same_min_dist)
		planned_x += width
		if x + width > strip_width:
			continue
		placements.append({"index": idx, "name": name, "x": x, "width": width})
		cursor = x + width + min_gap
		last_same[name] = x
	return placements


## 프리셋에 따라 고정 레이어의 노출을 바꾼다. 등불 줄과 근경 침전이 테마를 가른다.
func _apply_preset(preset: int) -> void:
	var lantern: ParallaxLayer = $L1Lantern as ParallaxLayer
	var near: ParallaxLayer = $L3Near as ParallaxLayer
	if preset == Preset.SHRINE_ALLEY:
		lantern.visible = false
		near.modulate = ALLEY_NEAR_MODULATE
	else:
		lantern.visible = true
		near.modulate = STREET_NEAR_MODULATE
	# 등불 줄의 고정 광원은 생성물이 아니라 씬 노드라 _clear_void_band가 닿지 않는다.
	# 서낭당에서는 공백 구간에 걸친 것만 꺼야 난색이 실제로 빠진다 (요청서 022 E-2-2)
	var void_band: bool = preset == Preset.SHRINE_SEONANG
	for child: Node in lantern.get_children():
		var light: PointLight2D = child as PointLight2D
		if light == null:
			continue
		var x: float = light.position.x
		light.visible = not (void_band and x > SHRINE_VOID_MIN and x < SHRINE_VOID_MAX)


## 방이 선언한 프리셋 이름을 Preset 값으로 바꾼다. 모르는 이름은 좌판 거리로 본다.
static func preset_from_name(name_value: String) -> int:
	return int(PRESET_BY_NAME.get(name_value, Preset.STREET))


func _clear_generated(parent: Node2D) -> void:
	for child: Node in parent.get_children():
		child.queue_free()


## 배경 광원 하나를 만든다. 레이어 범위를 반드시 넣어야 배경 캔버스를 비춘다
## (LIGHT_LAYER_MIN 주석 참고). 배경 광원은 전부 이 함수를 거친다.
static func _make_light(color: Color, energy: float, texture_scale: float) -> PointLight2D:
	var light: PointLight2D = PointLight2D.new()
	light.texture = GLOW_TEXTURE
	light.color = color
	light.energy = energy
	light.texture_scale = texture_scale
	light.range_layer_min = LIGHT_LAYER_MIN
	light.range_layer_max = LIGHT_LAYER_MAX
	return light


## 빛 웅덩이와 훈기가 공유하는 가산 합성 머티리얼을 돌려준다.
func _ensure_glow_material() -> CanvasItemMaterial:
	if _glow_material == null:
		_glow_material = CanvasItemMaterial.new()
		_glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _glow_material


## 구조물을 배치하고 군상 앵커 목록 [{"x", "width", "crowd"}]를 반환한다.
func _spawn_props(
	parent: Node2D,
	pool: Array[Dictionary],
	count: int,
	min_gap: float,
	same_min_dist: float,
	affinity: Dictionary,
	rng: RandomNumberGenerator
) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for prop: Dictionary in pool:
		(
			entries
			. append(
				{
					"name": String(prop["name"]),
					"width": float((prop["tex"] as Texture2D).get_width()),
					"max": int(prop["max"]),
				}
			)
		)
	var placements: Array[Dictionary] = plan_layout(
		rng, entries, count, STRIP_WIDTH, min_gap, same_min_dist, affinity, LAYOUT_CANDIDATES
	)
	var placed: Array[Dictionary] = []
	for placement: Dictionary in placements:
		var prop: Dictionary = pool[int(placement["index"])]
		var tex: Texture2D = prop["tex"] as Texture2D
		var sprite: Sprite2D = Sprite2D.new()
		sprite.centered = false
		sprite.texture = tex
		sprite.position = Vector2(
			float(placement["x"]), float(prop["bottom"]) - float(tex.get_height())
		)
		parent.add_child(sprite)
		(
			placed
			. append(
				{
					"name": String(placement["name"]),
					"x": float(placement["x"]),
					"width": float(tex.get_width()),
					"height": float(tex.get_height()),
					"bottom": float(prop["bottom"]),
					"crowd": int(prop["crowd"]),
				}
			)
		)
	return placed


## 구조물에 따뜻한 등불 광원을 확률적으로 붙인다 (환한 야시장의 빛 웅덩이).
func _spawn_prop_glows(
	parent: Node2D,
	anchors: Array[Dictionary],
	chance: float,
	energy: float,
	glow_scale: float,
	rng: RandomNumberGenerator
) -> void:
	for anchor: Dictionary in anchors:
		if rng.randf() >= chance:
			continue
		var light: PointLight2D = _make_light(WARM_GLOW_COLOR, energy, glow_scale)
		var glow_x: float = float(anchor["x"]) + float(anchor["width"]) * rng.randf_range(0.3, 0.7)
		var glow_y: float = (
			float(anchor["bottom"]) - float(anchor["height"]) * rng.randf_range(0.55, 0.8)
		)
		light.position = Vector2(glow_x, glow_y)
		light.set_script(LANTERN_SCRIPT)
		parent.add_child(light)


## 군상(행인)을 배치한다. 쏠림 방지 규칙 (2026-08-04 지시):
## - 앵커(crowd 가중치 비례)를 순환 배정해 모든 판에 고루 선다
## - CROWD_STROLL_CHANCE 비율은 앵커 없이 거리를 걷는 행인으로 빈 구간을 채운다
## - 군상끼리 CROWD_MIN_DIST 미만이면 재추첨해 한 점 뭉침을 막는다
## - 정면/뒷모습/특수를 섞고(_pick_crowd_texture), 활동 인물 x 목록(occupied)을
##   이어받아 활동 장면 위에 겹치지 않는다 (2026-08-05)
func _spawn_crowd(
	parent: Node2D,
	anchors: Array[Dictionary],
	count: int,
	bottom: float,
	rng: RandomNumberGenerator,
	occupied: Array[float] = []
) -> void:
	var weighted: Array[Dictionary] = []
	for anchor: Dictionary in anchors:
		for i: int in range(int(anchor["crowd"])):
			weighted.append(anchor)
	for i: int in range(weighted.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: Dictionary = weighted[i]
		weighted[i] = weighted[j]
		weighted[j] = swap
	var placed_x: Array[float] = occupied.duplicate()
	for i: int in range(count):
		var tex: Texture2D = _pick_crowd_texture(rng)
		var max_x: float = STRIP_WIDTH - float(tex.get_width())
		var x: float = 0.0
		for attempt: int in range(CROWD_RETRIES):
			if weighted.is_empty() or rng.randf() < CROWD_STROLL_CHANCE:
				x = rng.randf_range(0.0, max_x)
			else:
				var anchor: Dictionary = weighted[(i + attempt) % weighted.size()]
				x = float(anchor["x"]) + rng.randf_range(-28.0, float(anchor["width"]) + 12.0)
				x = clampf(x, 0.0, max_x)
			if _far_from_all(x, placed_x, CROWD_MIN_DIST):
				break
		placed_x.append(x)
		var figure: Sprite2D = Sprite2D.new()
		figure.centered = false
		figure.texture = tex
		figure.position = Vector2(x, bottom - float(tex.get_height()) + rng.randf_range(-1.0, 1.0))
		figure.flip_h = rng.randf() < 0.5
		figure.set_script(CROWD_SCRIPT)
		parent.add_child(figure)


static func _far_from_all(x: float, existing: Array[float], min_dist: float) -> bool:
	for value: float in existing:
		if absf(x - value) < min_dist:
			return false
	return true


## 풀에서 텍스처 하나를 뽑는다.
static func _pick_texture(pool: Array[Texture2D], rng: RandomNumberGenerator) -> Texture2D:
	return pool[rng.randi_range(0, pool.size() - 1)]


## 행인 텍스처 추첨. 특수(아이, 고양이) -> 뒷모습 -> 정면 순서의 확률 구간.
func _pick_crowd_texture(rng: RandomNumberGenerator) -> Texture2D:
	var roll: float = rng.randf()
	if roll < CROWD_EXTRA_CHANCE:
		return _pick_texture(CROWD_EXTRA_TEXTURES, rng)
	if roll < CROWD_EXTRA_CHANCE + CROWD_BACK_CHANCE:
		return _pick_texture(CROWD_BACK_TEXTURES, rng)
	return _pick_texture(CROWD_FRONT_TEXTURES, rng)


## 군상 한 명을 놓는 공용 헬퍼 (활동 장면 전용).
## flip_lock이 true면 반전을 고정한다 (씨름 대전처럼 방향이 의미인 배치).
func _put_figure(
	parent: Node2D, tex: Texture2D, x: float, bottom: float, flip: bool, flip_lock: bool
) -> void:
	var figure: Sprite2D = Sprite2D.new()
	figure.centered = false
	figure.texture = tex
	figure.position = Vector2(
		clampf(x, 0.0, STRIP_WIDTH - float(tex.get_width())),
		bottom - float(tex.get_height())
	)
	figure.flip_h = flip
	figure.set_script(CROWD_SCRIPT)
	if flip_lock:
		figure.set("flip_chance", 0.0)
	parent.add_child(figure)


## 근경 활동 장면 (2026-08-05 복작복작 디렉팅).
## 씨름판에는 대전 한 쌍과 구경꾼, 노름판에는 둘러앉은 판꾼, 좌판과 주막에는
## 등을 보이는 손님을 붙인다. 반환값은 배치 x 목록 (행인 겹침 회피용).
func _spawn_activities(
	parent: Node2D, placed: Array[Dictionary], rng: RandomNumberGenerator
) -> Array[float]:
	var busy: Array[float] = []
	var mats_used: int = 0
	for anchor: Dictionary in placed:
		var name: String = String(anchor.get("name", ""))
		var ax: float = float(anchor["x"])
		var aw: float = float(anchor["width"])
		var ab: float = float(anchor["bottom"])
		if name == "ring":
			_spawn_ssireum_match(parent, ax, aw, ab, rng, busy)
		elif name == "mat" and mats_used < ACTIVITY_MAT_MAX:
			mats_used += 1
			_spawn_gambling_circle(parent, ax, aw, ab, rng, busy)
		elif name == "tavern" or name == "stall_fruit":
			_spawn_shoppers(parent, ax, aw, ab, rng, busy)
	return busy


## 씨름 대전: 판 중앙에서 마주 잡은 두 명 + 판 가장자리 구경꾼 + 등 보이는 관중.
func _spawn_ssireum_match(
	parent: Node2D, ax: float, aw: float, ab: float, rng: RandomNumberGenerator, busy: Array[float]
) -> void:
	var cx: float = ax + aw * 0.5
	var left_tex: Texture2D = CROWD_WRESTLER_TEXTURES[0]
	var right_tex: Texture2D = CROWD_WRESTLER_TEXTURES[1]
	_put_figure(parent, left_tex, cx - float(left_tex.get_width()) + 4.0, ab - 3.0, false, true)
	_put_figure(parent, right_tex, cx - 2.0, ab - 3.0, true, true)
	busy.append(cx)
	var watchers: int = rng.randi_range(2, 3)
	for i: int in range(watchers):
		var tex: Texture2D = _pick_texture(CROWD_CHEER_TEXTURES, rng)
		var on_left: bool = i % 2 == 0
		var wx: float = ax + aw + rng.randf_range(0.0, 8.0)
		if on_left:
			wx = ax - 14.0 - rng.randf_range(0.0, 8.0)
		_put_figure(parent, tex, wx, ab, not on_left, true)
		busy.append(wx)
	var back_tex: Texture2D = _pick_texture(CROWD_BACK_TEXTURES, rng)
	var bx: float = cx + rng.randf_range(-16.0, 10.0)
	_put_figure(parent, back_tex, bx, ab + 3.0, rng.randf() < 0.5, false)
	busy.append(bx)


## 노름판: 멍석을 둘러앉은 판꾼들. 앞줄은 등을 보이고 건너편 한 명이 마주 본다.
func _spawn_gambling_circle(
	parent: Node2D, ax: float, aw: float, ab: float, rng: RandomNumberGenerator, busy: Array[float]
) -> void:
	var front_a: float = ax + aw * rng.randf_range(0.05, 0.2)
	var front_b: float = ax + aw * rng.randf_range(0.55, 0.7)
	for fx: float in [front_a, front_b]:
		var front_tex: Texture2D = _pick_texture(CROWD_BACK_TEXTURES, rng)
		_put_figure(parent, front_tex, fx, ab + 2.0, rng.randf() < 0.5, false)
		busy.append(fx)
	var far_x: float = ax + aw * rng.randf_range(0.3, 0.5)
	var far_tex: Texture2D = _pick_texture(CROWD_FRONT_TEXTURES, rng)
	_put_figure(parent, far_tex, far_x, ab - 3.0, rng.randf() < 0.5, false)
	busy.append(far_x)
	if rng.randf() < 0.5:
		var side_x: float = ax + aw + rng.randf_range(2.0, 10.0)
		_put_figure(parent, _pick_texture(CROWD_CHEER_TEXTURES, rng), side_x, ab, true, true)
		busy.append(side_x)


## 좌판 손님: 계산대 앞에 등을 보이고 선다. 둘이 붙으면 흥정 장면이 된다.
func _spawn_shoppers(
	parent: Node2D, ax: float, aw: float, ab: float, rng: RandomNumberGenerator, busy: Array[float]
) -> void:
	if rng.randf() < 0.25:
		return
	var x: float = ax + aw * rng.randf_range(0.25, 0.6)
	var tex: Texture2D = _pick_texture(CROWD_BACK_TEXTURES, rng)
	_put_figure(parent, tex, x, ab + 1.0, rng.randf() < 0.5, false)
	busy.append(x)
	if rng.randf() < 0.35:
		var x2: float = x + rng.randf_range(14.0, 22.0)
		var tex2: Texture2D = _pick_texture(CROWD_BACK_TEXTURES, rng)
		_put_figure(parent, tex2, x2, ab + 1.0, rng.randf() < 0.5, false)
		busy.append(x2)


## 중경 좌판 손님: 실루엣 층에도 등 보이는 손님을 세워 거리 안쪽까지 붐비게 한다.
func _spawn_mid_customers(
	parent: Node2D, placed: Array[Dictionary], rng: RandomNumberGenerator
) -> Array[float]:
	var busy: Array[float] = []
	for anchor: Dictionary in placed:
		if rng.randf() < 0.4:
			continue
		var x: float = float(anchor["x"]) + float(anchor["width"]) * rng.randf_range(0.25, 0.65)
		var tex: Texture2D = _pick_texture(CROWD_BACK_TEXTURES, rng)
		var bottom: float = float(anchor["bottom"]) + 1.0
		_put_figure(parent, tex, x, bottom, rng.randf() < 0.5, false)
		busy.append(x)
	return busy


## 도깨비불 광원을 흩는다 (근경 전용). 등불보다 빠르고 큰 진폭으로 일렁인다.
func _spawn_fires(parent: Node2D, count: int, rng: RandomNumberGenerator) -> void:
	for i: int in range(count):
		var light: PointLight2D = _make_light(DOKKAEBI_FIRE_COLOR, 0.45, 1.2)
		var fire_x: float = rng.randf_range(24.0, STRIP_WIDTH - 24.0)
		light.position = Vector2(fire_x, 310.0 + rng.randf_range(-4.0, 2.0))
		light.set_script(LANTERN_SCRIPT)
		light.set("energy_amount", 0.3)
		light.set("period", 1.5)
		light.set("sway_pixels", 2.0)
		parent.add_child(light)


## 거리 등불: 시장 중간 중간의 독립 광원. 라이트와 바닥 빛 웅덩이를 쌍으로 깐다.
## 좌판 거리의 조명 리듬을 만들고 (DESIGN_ACT1 2.5, 3.4) 어두운 구간을 없앤다.
func _spawn_street_lights(parent: Node2D, rng: RandomNumberGenerator) -> void:
	var x: float = rng.randf_range(24.0, STREET_LIGHT_STEP_MIN)
	while x < STRIP_WIDTH:
		var pool: Sprite2D = Sprite2D.new()
		pool.texture = GLOW_TEXTURE
		pool.material = _ensure_glow_material()
		pool.position = Vector2(x, POOL_BOTTOM)
		pool.scale = Vector2(rng.randf_range(1.6, 2.4), rng.randf_range(0.34, 0.5))
		pool.modulate = Color(POOL_COLOR, rng.randf_range(POOL_ALPHA_MIN, POOL_ALPHA_MAX))
		parent.add_child(pool)
		var energy: float = rng.randf_range(STREET_LIGHT_ENERGY_MIN, STREET_LIGHT_ENERGY_MAX)
		var light: PointLight2D = _make_light(WARM_GLOW_COLOR, energy, rng.randf_range(0.85, 1.05))
		light.position = Vector2(x, STREET_LIGHT_Y + rng.randf_range(-4.0, 4.0))
		light.set_script(LANTERN_SCRIPT)
		parent.add_child(light)
		x += rng.randf_range(STREET_LIGHT_STEP_MIN, STREET_LIGHT_STEP_MAX)


## 시장 전체에 옅은 난색 훈기를 깐다. 개별 등불이 아니라 거리 전체의 온기를 만든다.
func _spawn_haze(parent: Node2D, rng: RandomNumberGenerator) -> void:
	var step: float = STRIP_WIDTH / float(HAZE_COUNT)
	for i: int in range(HAZE_COUNT):
		var haze: Sprite2D = Sprite2D.new()
		haze.texture = GLOW_TEXTURE
		haze.material = _ensure_glow_material()
		haze.position = Vector2(
			step * (float(i) + 0.5) + rng.randf_range(-20.0, 20.0),
			HAZE_Y + rng.randf_range(-8.0, 8.0)
		)
		haze.scale = Vector2(rng.randf_range(4.5, 6.5), rng.randf_range(1.3, 1.9))
		haze.modulate = Color(HAZE_COLOR, HAZE_ALPHA)
		parent.add_child(haze)


## 불똥을 흩는다. 대기 밀도를 만드는 요소다 (ART_STYLE 5장).
func _spawn_embers(
	parent: Node2D, count: int, brightness: float, rng: RandomNumberGenerator
) -> void:
	var image: Image = Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	image.set_pixel(0, 0, Color.WHITE)
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	for i: int in range(count):
		var ember: Sprite2D = Sprite2D.new()
		ember.centered = false
		ember.texture = texture
		ember.material = _ensure_glow_material()
		ember.position = Vector2(
			rng.randf_range(0.0, STRIP_WIDTH), rng.randf_range(EMBER_TOP_Y + 24.0, EMBER_BOTTOM_Y)
		)
		var size: float = 1.0 if rng.randf() < 0.7 else 2.0
		ember.scale = Vector2(size, size)
		ember.modulate = Color(EMBER_COLOR, rng.randf_range(0.35, 0.8) * brightness)
		ember.set_script(EMBER_SCRIPT)
		ember.set("rise_speed", rng.randf_range(3.0, 9.0))
		ember.set("top_y", EMBER_TOP_Y)
		ember.set("bottom_y", EMBER_BOTTOM_Y)
		parent.add_child(ember)


## 밤구름. 고정 시드로 1회 생성한다 (하늘 채움, DESIGN_ACT1 2.3 L0).
func _build_clouds() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = CLOUD_SEED
	for i: int in range(CLOUD_COUNT):
		var cx: float = rng.randf_range(0.0, 512.0)
		var cy: float = rng.randf_range(CLOUD_Y_MIN, CLOUD_Y_MAX)
		var alpha: float = rng.randf_range(CLOUD_ALPHA_MIN, CLOUD_ALPHA_MAX)
		for p: int in range(rng.randi_range(2, 4)):
			var puff: Sprite2D = Sprite2D.new()
			puff.texture = GLOW_TEXTURE
			puff.position = Vector2(
				cx + float(p) * rng.randf_range(20.0, 46.0), cy + rng.randf_range(-6.0, 6.0)
			)
			puff.scale = Vector2(rng.randf_range(1.3, 2.4), rng.randf_range(0.34, 0.6))
			puff.modulate = Color(CLOUD_COLOR, alpha * rng.randf_range(0.6, 1.0))
			_clouds.add_child(puff)


## 원경 능선. 절차 생성 실루엣 2겹 (DESIGN_ACT1 2.3 L1).
func _build_ridges() -> void:
	var image: Image = Image.create_empty(RIDGE_WIDTH, RIDGE_HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	_draw_ridge(image, 58.0, 16.0, 0.7, 3.0, RIDGE_BACK_COLOR)
	_draw_ridge(image, 78.0, 11.0, 2.4, 5.0, RIDGE_FRONT_COLOR)
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.position = Vector2(0.0, RIDGE_BOTTOM - float(RIDGE_HEIGHT))
	_ridges.add_child(sprite)


## 능선 한 겹을 그린다. 사인 3개를 겹쳐 좌우가 이어지는 실루엣을 만든다.
## waves와 배음이 정수라 스트립 폭에서 파형이 닫힌다 (미러링 이음새 방지).
static func _draw_ridge(
	image: Image, base_y: float, amplitude: float, phase: float, waves: float, color: Color
) -> void:
	var width: int = image.get_width()
	var height: int = image.get_height()
	var step: float = TAU * waves / float(width)
	for x: int in range(width):
		var t: float = float(x) * step
		var wave: float = (
			sin(t + phase) * 0.6 + sin(t * 2.0 + phase * 1.7) * 0.28 + sin(t * 5.0 + phase) * 0.12
		)
		var top: int = maxi(int(base_y - wave * amplitude), 0)
		for y: int in range(top, height):
			image.set_pixel(x, y, color)


## 원경 별밭. 고정 시드로 1회 생성한다 (달과 별 상향 재분포, 2026-08-04 지시).
func _build_stars() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = STAR_SEED
	var image: Image = Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	image.set_pixel(0, 0, Color.WHITE)
	var star_texture: ImageTexture = ImageTexture.create_from_image(image)
	for i: int in range(STAR_COUNT):
		var star: Sprite2D = Sprite2D.new()
		star.centered = false
		star.texture = star_texture
		star.position = Vector2(
			rng.randf_range(0.0, 512.0), rng.randf_range(STAR_Y_MIN, STAR_Y_MAX)
		)
		var size: float = 1.0 if rng.randf() < 0.8 else 2.0
		star.scale = Vector2(size, size)
		star.modulate = Color(1.0, 1.0, rng.randf_range(0.82, 1.0), rng.randf_range(0.35, 0.9))
		_stars.add_child(star)
