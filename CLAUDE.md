# hgp - 로그라이크 2D 액션 플랫포머 (Godot)

## 프로젝트 개요

- 장르: 로그라이크 2D 액션 플랫포머
- 엔진: Godot 4.x (GDScript)
- 목표: 상용 출시. 1차 타깃 Steam PC, 콘솔은 W4 Games 경유로 후속 검토
- 개발: 1인 개발 + Claude Cowork 협업

## 개발 환경

- 개발은 Mac 단일 환경이다 (2026-07-29 Windows에서 전환, docs/DECISIONS.md)
- Cowork(Claude): 기획, 문서, 코드 작성과 검토. 샌드박스에서 Godot 에디터와 런타임은 실행 불가
- 사용자: 같은 Mac에서 Godot 에디터 실행, 플레이 테스트, 에셋 임포트, 빌드. Cowork 작업 폴더와 저장소가 동일해 파일 수정이 에디터에 바로 반영된다
- 원격 저장소는 git(github.com/Rarero/hgp). 커밋과 push는 사용자가 직접 수행한다
- 아트는 외부 API(PixelLab) 중심. 로컬 ComfyUI(Windows GPU) 경로는 폐기 (2026-07-29)
- PixelLab 산출물 처리 (2026-08-05 사용자 지침): 브라우저에서 내려받은 파일은 Claude가 직접 적절한 이름으로 바꿔 적절한 폴더로 옮기고 적용까지 진행한다. 생성 원본은 art_src/generated/pixellab/(grids, chars, anims, ui, archive), 인게임 에셋은 assets/sprites/ 아래다. 파일명은 CONVENTIONS의 소문자 스네이크케이스를 따른다. 다운로드 폴더에 남는 사본과 .com.google.Chrome.* 임시 파일은 사용자가 정리한다 (Cowork는 파일 삭제 권한이 없다)
- 크로스 플랫폼 규칙(줄바꿈, 경로, 파일명)은 docs/CONVENTIONS.md를 따른다

## 세션 규칙

- 응답은 한국어. 업무적이고 사실 중심, 간결하게. 이모지와 장식용 특수기호 사용 금지
- 작업 시작 전 docs/ROADMAP.md와 docs/PROGRESS.md에서 현재 상태를 확인
- 기술 및 기획의 주요 결정은 docs/DECISIONS.md에 기록한 뒤 진행
- 완료한 작업은 docs/PROGRESS.md에 날짜와 함께 기록
- 기획 관련 작업은 docs/GDD.md를 단일 기준으로 삼는다

## 문서 구조

- docs/GDD.md: 게임 디자인 문서 (기획의 단일 기준)
- docs/RUN_STRUCTURE.md: 런 거시 구조 (막, 층, 노드, 배치 규칙, 시간 예산, 점수제). 구조의 권위 문서
- docs/DECISIONS.md: 결정 기록
- docs/ROADMAP.md: 마일스톤과 일정
- docs/PROGRESS.md: 진행 로그 (주간 리포트 축적)
- docs/CONVENTIONS.md: 코드, 씬, 에셋 컨벤션
- docs/HARNESS.md: 개발 하네스 (검증 3계층, 버전 고정, 테스트 실행 절차)
- docs/PROTOTYPE.md: 프로토타입(M1) 범위 정의
- docs/ROOM_SPEC.md: 방 규격 (격자, 크기, 문 개구부, 필수 노드, 도달 가능성 기준, 충돌 레이어)
- docs/MAC_SETUP.md: Mac 개발 환경 셋업 (Godot 설치, GODOT_BIN, 첫 실행, 문제 대응). 환경 셋업의 진입점
- docs/M1_CHECKLIST.md: M1 스켈레톤의 실행 절차, 조작표, 튜닝 지점, 검증 항목
- docs/CONCEPT_BRIEF.md: 외부 전달용 컨셉 요약 (기준 문서 갱신 시 함께 갱신)
- docs/DESIGN_TRACK.md: 막별 디자인 세션 트랙(D 시리즈) 계획과 진행 상태
- docs/SESSION_PROMPTS.md: 세션 시작 프롬프트 모음 (게임 개발, 아트. 세션 분리 운영 원칙 포함)
- docs/DESIGN_ACT1.md, docs/DESIGN_ACT2.md: 1막, 2막 상세 디자인 (3막 DESIGN_ACT3.md는 D4에서 작성 예정)
- docs/DESIGN_INTRO.md: 타이틀 화면과 오프닝 시퀀스 설계 (프론트엔드)
- docs/DESIGN_HUB.md: 시작 허브(저승 초입 접수청) 설계
- docs/act1/: 1막 요소별 상세 (ENEMIES, EVENTS, MIDBOSS, BOSS)
- docs/systems/: 막 공통 시스템 상세 (RELICS 유물, BOONS 신내림 권능)
- docs/ART_PIPELINE.md, docs/ART_PIPELINE_SETUP.md: 아트 파이프라인 컨셉과 셋업 가이드 (외부 API PixelLab 중심, 2026-07-29 개정 완료)
- docs/ART_STYLE.md: 아트 스타일 가이드 (레퍼런스, 비례, 색, 디더링, 광원, 애니메이션 규칙. 2026-07-29 초안)
- docs/AUDIO.md: 오디오 (버스 구성, 배경음악 배치표, 재생 규칙, 파일 규격, 남은 작업. 2026-08-10)
- docs/ART_WEAPON_SPLIT.md: 플레이어 몸과 무기의 시각 분리 규격 (몸 단일 원본, 무기 오버레이와 앵커, 채택 게이트. 2026-08-07)
- reference/: 고증 자료 (act1_dokkaebi 도깨비, pantheon 신격과 무속 용어). 문화 요소 설계 시 근거로 삼는다

## 개발 규칙

- GDScript 우선, 정적 타이핑 사용. 스타일은 docs/CONVENTIONS.md 준수
- 씬(.tscn)과 스크립트(.gd)는 텍스트로 직접 작성 및 수정 가능
- .gd, .tscn, .tres를 작성하거나 수정하면 python tools/check.py를 실행해 통과를 확인한 뒤 완료로 보고한다 (docs/HARNESS.md)
- Claude 샌드박스에서는 Godot 에디터와 런타임을 실행할 수 없다. 플레이 테스트, 에셋 임포트 등 에디터가 필요한 검증은 사용자가 같은 Mac의 Godot 에디터에서 수행하도록 요청하고, 검증 항목을 명확히 정리해 전달한다
- 커밋 메시지 형식: "영역: 요약" (예: player: 이단 점프 구현)

## 아트 반입 규칙 (PixelLab)

- 사용자는 PixelLab 다운로드를 프로젝트 루트의 pixellab/ 폴더에 그대로 넣는다. 개명과 분류는 하지 않는다
- Cowork는 받은편함의 파일을 다음 순서로 처리한다
  1. 정체 확인. art_src/requests/의 요청서와 대조한다. 불명확하면 옮기지 말고 사용자에게 묻는다
  2. snake_case 규칙 이름으로 개명 (docs/CONVENTIONS.md, art_src/generated/pixellab/README.md 이름 규칙)
  3. 목적지로 이동. 생성 에셋은 art_src/generated/pixellab/의 분류 폴더(grids, objects, chars, anims, previews, ui, frontend, archive),
     스타일 기준으로 삼을 레퍼런스는 art_src/style_refs/, 도식과 비교 이미지는 art_src/references/로 보낸다
  4. S2 후처리와 인게임 반영까지 진행 (tools/pipeline/, assets/sprites/ 배치, 씬과 리소스 연결)
  5. 결과를 해당 요청서의 채택 결과란과 docs/PROGRESS.md에 기록
- 기존 채택본과 내용이 같은 재다운로드는 archive/로 보내고 _dup 또는 _reexport 접미사를 붙인다
- 파일은 삭제하지 않는다. 실행 환경이 마운트된 사용자 디스크의 삭제를 막고 있어 사용자가 허가해도 불가능하다. 삭제 대상은 art_src/generated/pixellab/_to_delete/로 모으고 사용자가 폴더째 지운다
- 조립 스크립트가 참조하는 원본을 옮기면 tools/pipeline/의 경로도 함께 고치고 재실행해 산출물이 같은지 확인한다

## 금지 사항

- 문서 확인 없이 기존 결정과 충돌하는 방향으로 작업하지 않는다
- GDD와 어긋나는 기능을 임의로 추가하지 않는다
