# player.tscn 변경 소유권 메모 (PLAYER_SCENE_CLAIMS)

최종 수정: 2026-08-07
상태: 운영 메모. 세션이 병행으로 돌 때 scenes/player/player.tscn 충돌을 복구하기 위한 기록
연동: docs/ART_WEAPON_SPLIT.md, docs/systems/WEAPONS.md, docs/DECISIONS.md 2026-08-07 G4 항목

## 왜 있나

2026-08-07에 DECISIONS.md가 병행 세션에 덮어쓰여 항목 두 개가 사라진 일이 있었다.
scenes/player/player.tscn은 그보다 위험이 크다. A6(검 아트, ART_WEAPON_SPLIT 마이그레이션)와
G4(무기 코드)가 같은 씬에 노드를 더하기 때문이다. 한쪽이 저장하면 다른 쪽 노드가 통째로 사라진다.

씬 파일은 텍스트지만 병합이 사람 눈으로만 되므로, 각 세션이 무엇을 더했는지 여기에 적어 둔다.
파일이 덮어써졌을 때 이 문서만 보고 다시 붙일 수 있는 것이 목적이다.

## 현재 등록된 변경

### G4 축소판 (2026-08-07, 무기 코드)

머리말 변경:

- `load_steps`를 14에서 15로 올림
- ext_resource 1줄 추가

```
[ext_resource type="PackedScene" path="res://scenes/player/weapon_melee.tscn" id="20_hwando"]
```

노드 추가 (`[node name="Camera2D" type="Camera2D" parent="."]` 바로 앞):

```
[node name="Hwando" parent="." instance=ExtResource("20_hwando")]
visible = false
```

- 위치: Player 직계 자식. Camera2D 앞이면 되고 순서 자체에 의미는 없다
- `visible = false`가 기본이다. 첫 대화 전 허브는 무기 0자루 상태이며 장착은 코드가 켠다
  (scenes/player/player.gd의 equip_melee_weapon, docs/systems/WEAPONS.md 2.1절 예외)
- 이 노드가 없으면 player.gd의 `hwando`가 null이 되고 근접이 기존 총검 경로로 조용히 되돌아간다.
  크래시는 없지만 검이 영영 안 나가므로 증상을 알아채기 어렵다

### A6 반입 / 무기 오버레이 (2026-08-07, 등록 완료)

머리말 변경:

- `load_steps`를 15에서 18로 올림
- ext_resource 3줄 추가

```
[ext_resource type="Script" path="res://scripts/weapons/weapon_sprite.gd" id="21_weapon_sprite"]
[ext_resource type="Texture2D" path="res://assets/sprites/weapons/hwando_angles.png" id="22_angles"]
[ext_resource type="Resource" path="res://resources/weapons/hwando_anchors.tres" id="23_anchors"]
```

노드 추가 (`BodyVisual`의 자식, `[node name="Shape"...]` 바로 앞):

```
[node name="WeaponSprite" type="Sprite2D" parent="BodyVisual"]
visible = false
script = ExtResource("21_weapon_sprite")
angles_texture = ExtResource("22_angles")
anchors = ExtResource("23_anchors")
```

- 위치가 BodyVisual의 자식인 것에 의미가 있다. 몸 뒤가 아니라 앞에 그려져야 하고,
  몸의 스쿼시와 스트레치를 함께 받아야 한다. Player 직계로 옮기면 둘 다 깨진다
- `Hwando`(WeaponMelee)와 역할이 다르다. Hwando는 판정과 상태 기계이고 이 노드는
  표시 전용이다. 합치지 않은 이유는 판정이 Player 기준 좌표이고 표시는 몸 클립 기준
  좌표이기 때문이다. 한 노드에 두면 좌표계가 섞인다
- 이 노드가 없으면 검이 손에 안 보인다. 판정과 이펙트는 그대로 나가므로 "보이지
  않는 칼로 벤다"가 되어 증상이 헷갈린다

## 절차

1. player.tscn을 고치는 세션은 이 문서에 자기 변경을 먼저 적는다
2. 씬을 열었더니 위 목록에 있는 노드가 없으면 덮어쓰기가 일어난 것이다. 목록대로 다시 붙인다
3. 다시 붙인 뒤 `python tools/compile_check.py`로 로드를 확인한다
4. `Hwando` 노드 복구 여부는 아래로 빠르게 본다. 대소문자가 다르므로 두 줄이 필요하다
   (ext_resource id는 소문자 `20_hwando`, 노드 이름은 대문자 `Hwando`다)

```
grep -c "20_hwando" scenes/player/player.tscn         # 2가 정상 (ext_resource 선언 1 + 노드 참조 1)
grep -c '\[node name="Hwando"' scenes/player/player.tscn   # 1이 정상
grep -c '\[node name="WeaponSprite"' scenes/player/player.tscn  # 1이 정상
```

## 변경 이력

- 2026-08-07: 신설. G4 축소판의 Hwando 노드 등록
- 2026-08-07: A6 반입의 WeaponSprite 노드 등록 (BodyVisual 자식)
