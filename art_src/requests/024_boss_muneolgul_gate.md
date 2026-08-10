# 에셋 요청서: 024 문얼굴 보스 (대문 공성전)

작성: 2026-08-07
목적: 1막 정규 보스 문얼굴(대문 그 자체가 보스)의 대문 구조물, 얼굴 2상태, 패턴 소품을 만든다. 2026-08-07 관문 공성전 재설계(docs/act1/BOSS.md 3.1) 기준이며, 구 설계(벽면 부조 + 이탈 본체)의 아트 목록은 전부 폐기한다
근거 문서: docs/act1/BOSS.md 3.1(스펙, 크기 규격, 고증 판정 항목), docs/ART_STYLE.md 2장(도깨비 고증 강제), 5장(배경/맵 분리, 아웃라인 신호), 9장(프롬프트 카드), reference/act1_dokkaebi/04_visual_catalog.md A1~A3, art_src/requests/019_tone_v2_characters.md(팔레트 정합)
선행: 없음 (얼굴은 캐릭터가 아니라 구조물에 그려진 도상이라 톤 v2 캐릭터 앵커 연쇄의 밖이다. 다만 팔레트 정합을 위해 reference image를 물린다)
사용자 지시 (2026-08-07): 보스는 연출부터 공을 들인다. 맵의 1/4을 채우는 대문이 보스다. 문에 그려진 도깨비 얼굴이 말을 하고("생자가 지나갈 길은 없다. 돌아가"), 눈이 플레이어를 바라보며 개전한다

주의: 방망이와 시장 중앙 광장 아레나는 이 요청서에서 뺐다. 방망이는 충돌 상자 확대 여부(최소 3배 규격 미달, BOSS.md 9장 판단 필요 항목)가 미결이라 규격 확정 전에 생성하면 재작업이 된다. 확정 후 별도 요청서로 진행한다.

## A. 배경과 현재 상태

문얼굴은 구현이 끝났으나 아트가 전부 임시다.

- 얼굴: 잡도깨비 스프라이트(dokkaebi_idle_e.png)를 정수 6배로 키워 쓴다
- 대문 구조물(문기둥, 상인방, 문짝 2, 어둠 배경): Polygon2D 단색 사각형
- 눈: Polygon2D 마름모 2개 (개전 응시와 광폭 적색을 엔진 착색으로 처리)
- 낙석, 바람 장애물: Polygon2D 다각형 (muneolgul_debris.tscn)

전투 흐름(요약): 개전 전 무적 대기, W 상호작용 2회로 개전(대사 후 눈 응시). 페이즈 1 지진(낙석)과 넘어지기(얼굴 판이 앞으로 쓰러짐, 엎어진 3초가 딜 창). 체력 70퍼센트에서 문짝이 열리며 잡도깨비 소환. 30퍼센트 광폭에서 배속과 바람(문이 열리고 강풍 + 장애물 직선 투척).

## B. 조형 방향과 고증 (절대 준수)

- 정체성: 시장 대문에 그려진(새겨진) 벽사 수문신. 명부에 없는 생자를 막는 완고한 관문지기. 순수 공포가 아니라 다소 인간적인 위엄
- 조형 근거: 부여 외리 문양전의 산수귀문전과 연대귀문전 (reference 04 A1). 뿔 없이 부릅뜬 큰 눈, 벌린 입, 갈기 같은 털
- 보조 근거: 귀면와의 눈/이빨/갈기/소용돌이 문양 차용 (reference 04 A2). 단, "도깨비 기와"로 단정하는 서술 금지(용면와설 이견). 게임 내 명칭은 "시장을 지키도록 세운 수문 도깨비 얼굴"
- 톤 근거: 얼굴무늬 수막새(보물 제2010호)의 무섭지 않은 인간적 표정 (reference 04 A3). 대기 상태의 반쯤 감은 눈에 반영한다
- 절대 금지 (BOSS.md 3.1 판정 체크리스트와 동일): 뿔, 호피 무늬, 가시 철퇴, 순수 빨강/파랑 단색 피부, 일본 요소 전부(오니, 스모, 사무라이, 기모노, 촌마게)
- 색 채널: 눈 발광은 주황/호박 계열(등불 규칙). 광폭의 적색은 엔진 착색으로 처리하므로 에셋에 적색을 굽지 않는다. 청록 금지(도깨비불 예약)
- 아웃라인: 대문과 얼굴은 플레이 오브젝트(보스)라 어두운 아웃라인을 유지한다. 귀문(bg_gwimun_gate)이 같은 예외 선례다 (ART_STYLE 5장 배경/맵 분리의 제외 대상)
- 라이팅: 플랫(알베도) 생성. 눈 글로우, 등불 빛무리는 엔진 담당

## C. 유닛별 규격

캔버스 크기 = 인게임 크기 (scale 1 목표). 조각 단위로 생성해 엔진에서 합성한다.

| # | 유닛 | 용도 | 캔버스 | 비고 |
|---|---|---|---|---|
| 1 | 얼굴 face_calm | 개전 전 대기. 반쯤 감은 눈 | 144x216 | 핵심 유닛. 수막새 톤 |
| 2 | 얼굴 face_awake | 개전 후 전 구간. 부릅뜬 눈 | 144x216 | 귀형 도상. 1과 같은 실루엣 강제 |
| 3 | 문짝 door_panel | 대문의 닫힌 문짝. 좌우는 미러 | 150x300 | 열림은 엔진 슬라이드라 1장이면 된다 |
| 4 | 문기둥 gate_pillar | 대문 좌측 기둥 | 60x352 | 우측은 화면 밖(벽) |
| 5 | 상인방 gate_lintel | 대문 윗보(가로 들보) | 360x52 | 기와 얹은 윗단 허용 |
| 6 | 낙석 rock_debris | 지진 패턴 낙하물 | 16x16 | 돌덩이 |
| 7 | 궤짝 crate_debris | 바람 패턴 투척물 | 20x16 | 시장 나무 궤짝 |
| 8 | 성벽 밴드 wall_band | 대문 좌측으로 이어지는 성벽 (배경 중경) | 240x120 | 후순위. 배경 카테고리(아웃라인 없음) |

- 어둠 배경(문짝 뒤 BackDark)은 단색이라 생성하지 않는다 (엔진 처리)
- 얼굴은 문짝 위에 겹쳐 그려지는 별도 조각이다. 문짝에 얼굴을 굽지 않는다 (넘어지기 때 얼굴 판만 분리되어 쓰러지는 연출)
- 쓰러진 얼굴은 엔진의 90도 회전으로 처리한다(픽셀 무손실). 낙하 중간 각도는 0.5초뿐이라 허용하고, 어색하면 중간 프레임 추가를 검증 후 판단한다 (H 기록)
- 눈 영역은 얼굴 중심 기준 위쪽(전체 높이의 약 4분의 1 지점)에 두 눈이 오게 한다. 엔진의 발광 오버레이와 광폭 착색이 눈 위치 마커(EyeL/EyeR, 얼굴 로컬 35,-228과 105,-228 상당)에 걸려 있어, 크게 어긋나면 마커를 재실측한다 (G절)

## D. 상태와 컷 정의

| 컷 | 상태 | 내용 |
|---|---|---|
| face_calm | 개전 전 | 눈을 반쯤 감고 이완된 위엄. 수막새의 미소에 가까운 조용한 얼굴 |
| face_awake | 개전 후 | 부릅뜬 큰 눈, 벌린 입. 산수귀문전의 귀형 도상. calm과 같은 실루엣과 갈기 |
| door_panel | 상시 | 세로로 긴 목재 문짝. 문살 또는 철징 장식 허용. 낡고 무거운 인상 |
| rock_debris | 지진 | 뭉툭한 돌덩이. 회갈색 |
| crate_debris | 바람 | 시장 물건 궤짝. 저채도 목재색 |

- 눈 응시 연출(개전 2회차)과 광폭 적색은 엔진이 처리한다. 별도 컷 불필요
- 대사 표시는 UI(Label)라 아트 범위 밖

## E. 생성 실행 카드 (ART_STYLE 9장 형식)

reference image 1: 얼굴 2컷은 art_src/style_refs/char_style_ref_saja_v3.png(세계 팔레트 정합), 구조물과 소품은 art_src/style_refs/act1_mood_anchor.png. 도구는 조각별로 Objects 또는 Create S-XL, A5 세션 재량.

### 1. face_calm (144x216)

```
SCALE: subject drawn at exact in-game size on a 144x216 canvas, fills most of the canvas
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: flat front view of a face carved and painted on a wooden gate, no perspective
PIXEL: chunky pixel art, low resolution, limited palette, flat shading
LIGHT: unlit, no glow, no halo, no baked lighting
CATEGORY: gameplay object, thin dark outline, readable silhouette, higher contrast
SUBJECT: a huge korean guardian spirit face painted on an old wooden gate,
based on baekje gwihyeong relief tiles, half-closed calm heavy-lidded eyes,
closed wide mouth with a faint stern smile like the silla smiling roof tile,
thick mane-like hair swirling around the face, broad flat nose, humanized dignity,
muted desaturated earth and dark wood tones, NO horns, NO oni, NO japanese demon,
no tiger stripes, no red skin, no blue skin, korean not japanese
```

### 2. face_awake (144x216)

face_calm 채택본을 reference image 2로 추가해 실루엣 동일성을 강제한다.

```
(헤더 동일)
SUBJECT: the same korean guardian gate face now fully awake, huge bulging wide-open
glaring eyes, mouth open showing flat teeth, same mane-like hair and same silhouette
as reference image 2, wrathful but dignified, not a demon, muted desaturated earth
and dark wood tones with dim warm amber iris, NO horns, NO oni, NO japanese demon,
no tiger stripes, no red skin, no blue skin, korean not japanese
```

### 3. door_panel (150x300)

```
SCALE: subject drawn at exact in-game size on a 150x300 canvas, fills most of the canvas
REFERENCE: match the palette, rendering and mood of reference image 1
VIEW: flat side view for a 2D platformer, no perspective, no isometric, no depth angle
PIXEL: chunky pixel art, low resolution, limited palette, flat shading
LIGHT: unlit, no glow, no halo, no baked lighting
CATEGORY: gameplay object, thin dark outline, readable silhouette, higher contrast
SUBJECT: one tall heavy wooden gate door panel of a korean traditional market gate,
dark aged wood planks with iron stud rows and a horizontal brace beam,
muted desaturated dark wood tones, no face on the door, korean not japanese
```

### 4. gate_pillar (60x352), 5. gate_lintel (360x52)

문짝과 같은 헤더. SUBJECT만 교체.

```
SUBJECT(기둥): a tall thick wooden gate pillar of a korean traditional gate,
dark aged wood with a stone base block, muted desaturated tones
SUBJECT(상인방): the top horizontal beam of a korean traditional gate with a narrow
giwa tile roof cap, dark aged wood and dark gray tiles, muted desaturated tones
```

### 6. rock_debris (16x16), 7. crate_debris (20x16)

```
SUBJECT(낙석): a chunky falling rock boulder, gray-brown stone, simple bold shape
SUBJECT(궤짝): a small wooden market crate, muted desaturated wood, simple bold shape
```

### 8. wall_band (240x120, 후순위)

배경 카테고리로 전환한다 (아웃라인 없음, bake_bg 파이프라인 통과).

```
CATEGORY: background piece, no outlines, desaturated muted dark indigo tones
SUBJECT: a low korean fortress wall band stretching sideways, stone base and
plaster upper with a narrow giwa tile top, night silhouette, flat and dark
```

## F. 판정 기준

- 고증 체크리스트 (BOSS.md 3.1, 전 항목 통과 필수): (1) 뿔 없음 (2) 호피 없음 (3) 가시 철퇴 없음 (4) 단색 빨강/파랑 피부 아님 (5) 도깨비 기와 단정 서술 없음 (6) 명칭 "수문 도깨비 얼굴" (7) 오니/서구 데몬과 구분되는 인간적 톤
- 위압감: 얼굴이 화면(480x270)에서 문 앞에 섰을 때 압도적으로 읽히는가. 대문 전체(360x352)가 화면 대부분을 채우는가
- 상태 대비: calm과 awake가 같은 얼굴로 읽히면서 눈만으로 개전 전후가 구분되는가
- 색 채널: 적색과 청록 없음. 눈 홍채는 호박 계열
- 밀도: 캔버스 = 인게임 크기. 세밀한 대형 일러스트풍 출력은 기각
- 분리: 얼굴이 문짝과 별도 조각인가 (문짝에 얼굴이 구워져 있으면 기각. 넘어지기 연출이 성립하지 않는다)
- 팔레트 정합: 기존 채택본(저승사자, 야시장 배경)과 나란히 두고 같은 세계로 읽히는가

## G. Godot 연결 계획

- 얼굴: scenes/bosses/dokkaebi_muneolgul.tscn의 BodyVisual/FaceVisual 텍스처 교체, scale 6 -> 1. calm/awake 전환은 start_encounter()에서 texture 스왑 한 줄 추가 (지금은 눈 착색만 바뀐다)
- 눈 오버레이: EyeL/EyeR(Polygon2D)은 발광/광폭 착색용으로 유지하되, 채택본의 실제 눈 위치에 맞춰 로컬 좌표를 재실측한다
- 대문: GateVisual 하위 PillarL/Lintel/DoorL/DoorR Polygon2D를 Sprite2D로 교체. DoorR은 door_panel 미러. BackDark 단색은 유지
- 소품: muneolgul_debris.tscn의 Visual(Polygon2D)을 Sprite2D로 교체하고 코드의 COLOR_CRATE modulate 분기를 텍스처 2종 분기로 바꾼다
- 판정 상자는 코드 상수(STAND_HURT, DOWN_HURT 등)라 아트 교체와 무관. 시각과 판정의 정합만 엔진에서 확인 (BOSS.md 9장)
- 참고 프리비즈: art_src/previz/muneolgul_gate_previz.png (레이아웃과 크기 비율 확인용)

## H. 진행 기록

- 2026-08-07 요청서 작성. 레이아웃 프리비즈(muneolgul_gate_previz.png) 함께 제작
- 2026-08-07 얼굴 2상태 1차 생성 완료 (PixelLab Objects, 216px 1프레임, Sidescroller, 프롬프트 생성)
  - face_calm: 반쯤 감은 눈과 잔잔한 미소, 소용돌이 갈기 테두리, 목재 저채도. 중앙에 나무판 이음선이 있어 문짝 두 짝에 걸친 얼굴 설정과 우연히 정합. 수막새 톤 재현 양호
  - face_awake: face_calm을 스타일 레퍼런스로 물리려 했으나 갤러리 참조를 붙이면 제출이 조용히 실패하는 문제가 있어(원인 미상, UI 이슈로 추정) 프롬프트에 "same swirling mane frame and silhouette"를 명시하는 방식으로 대체. 부릅뜬 둥근 눈, 벌린 입과 납작한 이빨 배열이 산수귀문전 도상과 직결. 고증 체크리스트(F절) 7항목 전원 통과 판정
  - 리뷰 캡처: art_src/work/boss_gate/muneolgul_face_v1_review.png (좌 awake, 우 calm)
  - 크기 주의: 캔버스가 216 정사각이라 얼굴 실폭이 규격(144)보다 넓다. Export 후 실측해 C절 규격 또는 씬 좌표(EyeL/R 마커, 피격 상자 시각 정합)를 조정한다
- 도구 확인 사항 (2026-08-07):
  - Objects의 Style Reference Images는 자체 갤러리 생성물 전용이다. 외부 이미지 업로드(파일 입력, 스크린샷 주입)는 받아들여지지 않았다. 수집 유물 사진은 프롬프트 서술로 반영했다 (산수귀문전의 부릅뜬 눈/벌린 입/갈기, 수막새의 미소를 영문 서술로 인코딩)
  - 갤러리 스타일 레퍼런스를 붙이면 Size/View가 참조물 크기로 잠긴다 (48px 참조를 고르면 216px 생성 불가). 216px 참조(face_calm)를 골랐을 때는 제출 자체가 실패했다
  - 생성 잔량: 2191/5000 (8월 30일 리셋). 이번 세션 소모 약 40~80
- 2026-08-07 잔여 유닛 생성/에셋화/씬 연결 완료 (성벽 밴드만 후순위로 남음)
  - 생성: 문짝(144px 4프레임 쌍문 4종, 태그 muneolgul_gate_door), 문기둥(176px, 공포와 주춧돌 포함), 상인방(176px 기와 갓 가로보), 낙석(32px 64종 중 회색 4종 채택, 태그 muneolgul_rock), 궤짝(32px 64종 중 3종 채택, 한글 가격표 포함, 태그 muneolgul_crate). 탈락 121종은 Dismiss. 13개체 일괄 Export(selected_objects.zip)
  - 크기 전략 확정: 구조물은 절반 크기 생성 후 정수 2배 확대. 문짝은 쌍문 콘텐츠(112x109)를 반으로 갈라 각 56x109 -> 2배 112x218을 좌우 문짝으로 사용(중앙 자물쇠가 개문 시 갈라지는 연출 겸용). 기둥 51x176 -> 102x352(공포 오버행 유지). 상인방 밴드 159x37 -> 2배 후 상단 52줄을 360폭으로 연장(muneolgul_lintel)하고 전체 밴드를 82줄/360폭으로 연장해 문 위 벽띠(muneolgul_gate_beam) 신설. 낙석/궤짝은 1배 트리밍(27x27 안팎)
  - 씬 연결: GateVisual의 Polygon2D 임시 5종을 실제 스프라이트로 교체(BackDark 어둠만 유지). 문짝 기준 위치 상수(DOOR_L/R_BASE_X)를 두고 개문 슬라이드를 기준값 상대로 수정. muneolgul_debris를 Sprite2D 기반으로 바꾸고 setup에 텍스처 인자 추가, 보스가 낙석 4종 중 무작위/궤짝 텍스처를 주입(rock_textures, crate_texture export)
  - 조립 확인: art_src/work/boss_gate/muneolgul_gate_assembled.png (대기/개전+개문/광각 낙석·궤짝 3컷)
  - 레이아웃 변화: 문짝 실물이 규격(각 150x284)보다 작아(각 112x218) 문 개구부가 어둠 인셋 안에 박힌 구성이 됐다. 문 위 공간은 신설 벽띠가 채운다. 시각-판정 정합은 변화 없음(판정은 코드 상수)
- 2026-08-07 Export와 에셋화 완료
  - ZIP 2종 수령 (the_same_huge_korean_guardian.zip = awake, huge_korean_guardian_spirit_fa.zip = calm. art_src/generated/pixellab/ 소재)
  - 실측: 두 상태 모두 216x216 캔버스. awake 콘텐츠 216x216(모서리까지), calm 콘텐츠 188x184(중앙 정렬). 콘텐츠 중심이 (108,108)/(108,106)으로 일치해 같은 좌표에서 텍스처 교체만으로 정렬된다. 깨어나며 갈기가 커지는 인상은 연출상 이점으로 채택
  - 눈 실측 (awake, 캔버스 좌표): 좌 (70,82), 우 (142,80), 반경 약 11px
  - 에셋: assets/sprites/bosses/muneolgul_face_calm.png, muneolgul_face_awake.png (scale 1, 트리밍 없음)
  - 씬 연결: FaceVisual 텍스처 교체(임시 스프라이트/hframes/scale 6 제거), face_calm/awake_texture export 신설. 두 번째 상호작용(응시)에서 calm -> awake 텍스처 교체(감은 눈이 번쩍 뜨이는 연출). 눈 오버레이(EyeL/R)를 실측 위치(로컬 32,-202 / 104,-204)로 옮기고 불투명 임시 눈에서 반투명 발광(평시 투명, 응시 호박 0.45, 광폭 적 0.6)으로 전환. EyeOrigin(광선 원점)도 (68,-203)으로 재실측
  - 인게임 구도 합성 확인: art_src/work/boss_gate/muneolgul_ingame_preview.png (dormant/awakened 카메라 뷰)
  - 실폭 판정: 얼굴 실폭 216이 규격(144)보다 넓지만 문짝 2장 폭(300) 안에 들어가고 화면 압도감이 사용자 의도에 부합해 216 유지. C절 규격을 216x216으로 갱신하는 것으로 확정. 피격 상자(STAND 160x220)는 시각보다 약간 좁은 관대한 판정으로 유지, 엔진 확인 항목
