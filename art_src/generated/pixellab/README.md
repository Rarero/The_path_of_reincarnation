# PixelLab 생성물 폴더 구조

2026-08-03 정리 (A1 세션), 2026-08-05 개정 (받은편함 도입, objects 분류 신설).
새 산출물은 아래 분류에 맞춰 저장한다.

## 반입 경로

다운로드는 프로젝트 루트의 pixellab/ (받은편함)에 들어온다. Cowork가 정체를 확인해
개명하고 이 폴더의 분류로 옮긴다. 절차는 pixellab/README.md를 따른다.

## 구조

- grids/ : PixelLab 생성 원본 그리드, 밴드, 타일셋 시트 (act1_l* = 요청서 008 구세대, act1_r_* = 요청서 011 스케일 규약 세대, act1_tileset_* = 요청서 021 지형 타일셋). 에셋 재추출의 원천이므로 삭제 금지
- objects/ : PixelLab Objects 도구 생성물 (48px 단품 오브젝트). 채택본은 접미사 없이, 변형 후보는 alt 또는 색 이름을 붙인다
- chars/ : 채택 캐릭터 Export (하위 폴더 = 압축 해제본, zip = 원본). 현재 char_player_v3~v5, char_dokkaebi_v4, char_saja_v1~v3, char_clerk_v1
- anims/ : 애니메이션 프레임 시트 (anim_in_* = 애니메이션 입력용 정지 프레임)
- previews/ : 판정용 미리보기 (셀 시트, 인게임 합성). 판정이 끝나면 archive로 이동
- ui/ : UI 생성물 (HUD 세트, 9-slice 패널)
- frontend/ : 타이틀, 인트로 등 프론트엔드 전용 생성물
- archive/ : 기각본, 구버전, 중복 재다운로드(_dup, _reexport 접미사). 이력 보존용이며 참조 금지
- _to_delete/ : 삭제 대상. Cowork는 파일을 지우지 않으므로 여기로 옮기고 사용자가 지운다

## 이름 규칙

- snake_case 소문자 (docs/CONVENTIONS.md)
- 형식: <막 또는 영역>_<종류>_<대상>[_변형][_크기].png (예: act1_tileset_giwa_16.png, act1_obj_stall_48.png)
- 채택본에는 변형 표기를 붙이지 않는다. 변형 후보만 alt, 색 이름, _rejected를 붙인다
- 크기 표기는 인게임 캔버스 크기 기준이며, 그리드는 셀 크기를 쓴다

## 규칙

- 채택본이 인게임 에셋이 되면 assets/sprites/ 아래로 베이크하고, 여기의 원본은 그대로 둔다
- 조립 스크립트(tools/pipeline/)가 참조하는 원본을 옮기면 스크립트 경로도 함께 고친다
- 문서(요청서 008~011)의 과거 로그에 적힌 경로는 정리 전 위치다. 현재 위치는 이 문서를 기준으로 찾는다
