extends GdUnitTestSuite

## 하네스 스모크 테스트.
## 실행 환경이 프로젝트에 고정된 기준과 일치하는지 검증한다.
## 이 테스트가 실패하면 코드가 아니라 환경(Godot 버전, 프로젝트 설정)을 먼저 확인한다.

const EXPECTED_GODOT_MAJOR: int = 4
const EXPECTED_GODOT_MINOR: int = 6


func test_godot_version_matches_pinned() -> void:
	var version: Dictionary = Engine.get_version_info()
	assert_int(version.major).is_equal(EXPECTED_GODOT_MAJOR)
	assert_int(version.minor).is_equal(EXPECTED_GODOT_MINOR)


func test_project_name_is_hgp() -> void:
	var project_name: String = ProjectSettings.get_setting("application/config/name")
	assert_str(project_name).is_equal("hgp")


func test_untyped_declaration_treated_as_error() -> void:
	var level: int = ProjectSettings.get_setting("debug/gdscript/warnings/untyped_declaration")
	assert_int(level).is_equal(2)
