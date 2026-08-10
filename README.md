# 환생길

차사의 실수로 저승에 끌려온 회사원이 잘못 적힌 수명부를 바로잡기 위해 도깨비 시장을 돌파하고 염라대전으로 향하는 한국 저승 판타지 로그라이크 2D 액션 플랫포머.

- 엔진: Godot 4.6.3 (GDScript)
- 아트: 픽셀아트 (논리 해상도 480 x 270)
- 입력: 키보드, 게임패드

## 플레이

- 웹 플레이: https://rarero.github.io/The_path_of_reincarnation/
- 플레이 영상: (YouTube 링크 기입)
- 로컬 실행: Godot 4.6.3을 설치하고 저장소를 클론한 뒤 project.godot를 열어 실행(F5)

## 게임 흐름

타이틀, 오프닝 컷툰(7페이지), 저승 초입 접수청(허브)을 거쳐 1막 도깨비 시장으로 들어간다. 노드 지도 위를 자유 이동하며 전투방, 이벤트, 신당, 내기방, 쉼터를 골라 진행하고, 막 보스를 처치하면 런이 끝난다. 사망하면 허브로 반송되며 해금 요소와 진행 플래그는 유지된다. 런 중단 저장과 이어하기를 지원한다.

- 신내림 권능: 신당에서 획득하고, 권능 두 개를 조합해 상위 티어로 강화
- 미니게임 3종: 씨름, 노름(투전, 골패, 쌍륙), 추격
- 생기 몰림: 전투방 제한 시간 초과 시 적과 플레이어의 공격력이 함께 상승

## 조작

| 동작 | 키보드 | 게임패드 |
|---|---|---|
| 이동 | A / D 또는 좌우 방향키 | 왼쪽 스틱, D패드 |
| 조준(상하) | W / S | D패드 상하 |
| 점프 | Space | A |
| 근접 공격(환도) | J | X |
| 원거리 공격(총, 해금 후) | K | RB |
| 재장전 | R | Y |
| 대시 | Shift | LB |
| 지도, 상태 창 | I | Back |
| 액티브 스킬 | L | R 스틱 클릭 |
| 신당 재추첨 / 권능 조합 | T / F | 지원 |
| 일시정지 | Esc | B |

## 웹 빌드와 배포

- 웹 export preset(`export_presets.cfg`의 `Web`)이 포함되어 있다. 스레드 미사용 빌드라 별도 서버 헤더 없이 GitHub Pages에서 동작한다
- `main` 브랜치에 push하면 GitHub Actions(`.github/workflows/deploy_web.yml`)가 웹 빌드를 만들어 GitHub Pages로 배포한다. 저장소 Settings, Pages에서 Source를 GitHub Actions로 설정하면 https://rarero.github.io/The_path_of_reincarnation/ 에서 플레이할 수 있다
- 로컬 수동 빌드: `godot --headless --import` 후 `godot --headless --export-release "Web" build/web/index.html`

## 폴더 구조

| 폴더 | 내용 |
|---|---|
| scenes/ | 씬(.tscn)과 씬 스크립트. player, enemies, bosses, levels, hub, minigame, cutscene, ui |
| scripts/ | 씬에 종속되지 않는 공용 스크립트 (맵 생성, 시스템, 데이터 정의) |
| autoload/ | 싱글톤 (게임 상태, 씬 라우터, 런 상태, 세이브, 오디오) |
| resources/ | 밸런스 데이터(.tres)와 오디오 버스 레이아웃 |
| assets/ | 스프라이트, BGM, 폰트 |
| docs/ | 설계 문서. 기획 기준은 docs/GDD.md |
| tests/ | gdUnit4 단위 테스트 |
| tools/ | 정적 검사 하네스(check.py), 아트 후처리 스크립트 |
| addons/ | gdUnit4 (테스트 프레임워크) |
| art_src/ | 아트 생성 원본과 요청서 |
| reference/ | 도깨비, 신격 등 고증 자료 |
| submission/ | 제출 문서 (게임 소개서, AI 활용 기술 문서, 팀원 롤 기술서) |
| .github/workflows/ | CI(정적 검사, 단위 테스트)와 웹 배포 |

## 개발 방식과 AI 활용

- 기획과 코드: Claude. 설계 문서(GDD)를 단일 기준으로 두고 GDScript와 씬 파일을 텍스트로 작성
- 아트: PixelLab. 픽셀아트 생성 후 Python 후처리와 Aseprite 마감을 거쳐 반영
- 음악: Google Cloud Vertex AI Lyria. 화면별 BGM 7곡, 프롬프트는 BGM_PROMPTS.md
- 검증: tools/check.py 정적 검사, gdUnit4 단위 테스트, GitHub Actions CI

상세는 submission/ai_usage.docx 참고.

## 팀

- 황상원: 게임 전체 설계
- 김민형: 게임 구현 (코드 레벨)
- 나상우: 아트 및 사운드 생산

## 외부 에셋과 라이선스

- Godot Engine 4.6.3: MIT
- gdUnit4 (addons/gdUnit4): MIT
- Galmuri 폰트 (assets/fonts): SIL OFL 1.1, 라이선스 전문 동봉
- 그 외 스프라이트와 배경음악은 PixelLab과 Vertex AI Lyria로 자체 제작
