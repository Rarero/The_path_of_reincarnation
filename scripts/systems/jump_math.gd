class_name JumpMath
extends RefCounted

## 점프 파라미터 계산 (순수 로직, 단위 테스트 대상).
##
## 기획은 점프 높이를 타일 수로 정의한다 (docs/PROTOTYPE.md: 3.5타일).
## 튜닝 입력은 "높이(타일), 상승 시간, 하강 시간"이고
## 실제 물리 값(중력, 초기 속도)은 여기서 파생시킨다.
## 상승 중력과 하강 중력을 분리해 체공감을 만든다.


## 높이(px)와 상승 시간으로 점프 초기 속도를 구한다. 결과는 위 방향(음수).
static func jump_velocity(height_px: float, time_to_peak: float) -> float:
	if time_to_peak <= 0.0:
		return 0.0
	return -2.0 * height_px / time_to_peak


## 높이(px)와 상승 시간으로 상승 구간 중력을 구한다.
static func rise_gravity(height_px: float, time_to_peak: float) -> float:
	if time_to_peak <= 0.0:
		return 0.0
	return 2.0 * height_px / (time_to_peak * time_to_peak)


## 높이(px)와 하강 시간으로 하강 구간 중력을 구한다.
static func fall_gravity(height_px: float, time_to_descent: float) -> float:
	if time_to_descent <= 0.0:
		return 0.0
	return 2.0 * height_px / (time_to_descent * time_to_descent)


## 타일 수를 픽셀 높이로 변환한다.
static func tiles_to_pixels(tiles: float, tile_size: int) -> float:
	return tiles * float(tile_size)


## 초기 속도와 상승 중력으로 도달 높이(px)를 역산한다. 검증용.
static func peak_height(velocity: float, gravity: float) -> float:
	if gravity <= 0.0:
		return 0.0
	return (velocity * velocity) / (2.0 * gravity)
