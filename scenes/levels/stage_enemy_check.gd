extends Node2D

## 적 확인용 검증 스테이지 (F6으로 이 씬만 실행).
##
## 1막 확정 6종을 왼쪽부터 정해진 순서로 세워 실루엣과 행동을 한 화면에서 본다.
## 개체 위에 이름을 띄우지 않는다 (2026-08-09 사용자 지시). 순서로 식별한다.
## 정식 런(run_stage)은 방마다 예산과 패턴이 달라 특정 개체를 보려면 운이 필요하다.
## "구현이 됐는가"와 "화면에서 구분되는가"를 분리해 확인하려고 둔 씬이다 (2026-08-09).
##
## 조작은 정식 게임과 같다. 좌우 이동, 점프, 공격, 대시.

## 왼쪽부터 세울 순서와 x 좌표 (px)
const LINEUP: Array = [
	[&"goblin_charger", 180],
	[&"lantern_shooter", 300],
	[&"fence_dokkaebi", 420],
	[&"ssireum_wrestler", 540],
	[&"egg_dokkaebi", 660],
]
## 적을 세우는 바닥 높이 (px)
const GROUND_Y: float = 336.0

@onready var _enemies_root: Node2D = $Enemies as Node2D
@onready var _notice: Label = $Ui/Notice as Label


func _ready() -> void:
	var lines: PackedStringArray = PackedStringArray()
	var placed: int = 0
	for item: Array in LINEUP:
		var id: StringName = item[0]
		if not SpawnCatalog.is_available(id):
			lines.append("%s 배치 불가 (씬 또는 스탯 없음)" % String(id))
			continue
		var path: String = SpawnCatalog.scene_path(id)
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			lines.append("%s 씬 로드 실패 (%s)" % [String(id), path])
			continue
		var enemy: EnemyBase = packed.instantiate() as EnemyBase
		if enemy == null:
			lines.append("%s EnemyBase 아님" % String(id))
			continue
		_enemies_root.add_child(enemy)
		enemy.global_position = Vector2(float(item[1]), GROUND_Y)
		placed += 1
	if lines.is_empty():
		var order: PackedStringArray = PackedStringArray()
		for item: Array in LINEUP:
			order.append(SpawnCatalog.display_name(item[0] as StringName))
		_notice.text = "적 %d종. 왼쪽부터  %s" % [placed, "  /  ".join(order)]
	else:
		_notice.text = "문제 %d건\n%s" % [lines.size(), "\n".join(lines)]
	print("[적 확인] 배치 %d종, 배치 가능 목록=%s" % [placed, SpawnCatalog.available_enemy_ids()])
