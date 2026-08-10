extends Node

## 런 중단 저장 (오토로드: SaveGame).
##
## 진행 중인 런 하나를 파일에 저장해 다음에 이어서 하게 한다 (docs/DECISIONS.md 2026-08-04).
## 세이브 스커밍이 아니라 단일 슬롯 중단 저장이다. 사망 또는 완주 시 clear로 삭제한다.
## 재개 지점은 방(노드) 시작 단위다. run_stage가 방 진입마다 자동 저장한다.

const SAVE_PATH: String = "user://run_suspend.json"
const SAVE_VERSION: int = 1

## 타이틀 이어하기가 넘긴 재개 데이터. run_stage가 _ready에서 소비한다
var _resume_data: Dictionary = {}
var _resume_requested: bool = false


## 저장 파일이 있으면 true (이어하기 버튼 노출 판단).
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## 저장 데이터를 파일에 쓴다.
func write(data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("저장 실패: %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data))
	file.close()


## 저장 데이터를 읽는다. 없거나 손상이면 빈 사전.
func read() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}


## 저장 파일을 삭제한다 (사망, 완주). 남은 저장이 없어 이어하기 버튼이 사라진다.
func clear() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


## 타이틀 이어하기: 재개 데이터를 올린다. run_stage가 소비한다.
func request_resume(data: Dictionary) -> void:
	_resume_data = data
	_resume_requested = true


## 재개 요청이 대기 중이면 true.
func is_resuming() -> bool:
	return _resume_requested


## 재개 데이터를 소비한다 (요청 플래그를 내린다).
func consume_resume() -> Dictionary:
	_resume_requested = false
	var data: Dictionary = _resume_data
	_resume_data = {}
	return data
