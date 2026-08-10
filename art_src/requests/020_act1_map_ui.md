# 에셋 요청서: act1_map_ui (지도 노드 선택 화면)

작성: 2026-08-04 (A4 세션)
목적: 지도(노드 선택 화면)의 옛 회화식 고지도 화면을 PixelLab로 제대로 생성한다. 코드 드로잉
플레이스홀더(node_map.gd, 파이썬 생성 map_paper.png와 먹선 아이콘 6종)를 교체한다.
근거 문서: docs/RUN_STRUCTURE.md 2/7장, docs/DECISIONS.md 2026-08-04 지도 아트 방향 2차, docs/ART_STYLE.md 9장
레퍼런스: art_src/style_refs/reference_shots/map_old_gojido.png (조선 회화식 군현지도, 광주목. 구도와 질감 기준)

## 확정 방향 (사용자, 2026-08-04)

- 무채색 먹선 옛 지도. 색은 뺀다 (고지도의 옅은 채색도 배제, 세피아 먹 단색)
- 손에 펼쳐 든 느낌 (하단 좌우 엄지)
- 노드 아이콘은 사물이 아니라 인상을 전한다. 색 원 도형과 유치한 캐릭터 아이콘 폐기
- 인상 매핑: 위험(전투), 매우 위험(중간보스), 알 수 없음(이벤트/내기), 좋음(상점/쉼터), 신비(신당), 보스(막 보스, 별도)

## 도구와 공통 규칙

- 도구: Create S-XL image (Pro). 배경 제거는 아이콘에서만 사용
- 무채색 강제: monochrome, sepia ink, no color, no bright hue
- 캔버스 크기 = 인게임 등장 크기 (ART_STYLE 9장). 게임 논리 해상도 480x270
- 글자 굽기 금지 (UI 텍스트는 엔진 폰트)

## 1. 지도 종이 배경 (map_paper)

- 유형: 배경(UI 일러스트) / 최종 크기: 440x236 (화면 480x270 중앙, 여백 20)
- 상태: 대기

프롬프트:

```
old korean joseon-era hand-drawn provincial map on aged hanji paper,
painterly antique cartography, faint sparse ink mountain ranges only along the top edge,
one thin winding river, worn and frayed paper edges, subtle stains and creases,
monochrome sepia ink line art, no color, no text, no labels,
the center and lower area kept mostly empty pale paper for markers,
chunky pixel art, low resolution, limited muted palette, flat, no perspective grid
```

- 파라미터: 440x236 (Custom size), 배경 제거 끔
- 판정 기준: 중앙과 하단이 비어 노드가 얹힐 여백이 있는지, 상단 산수만 은은한지, 완전 무채색인지, 픽셀 밀도(굵은 픽셀)인지. 미세 일러스트풍이면 기각

## 2. 손 (map_hands) - 손에 든 연출

- 유형: 오브젝트(UI) / 최종 크기: 각 64x80 내외, 좌우 1쌍
- 상태: 대기

프롬프트:

```
a pair of human hands gripping the bottom edge of a paper map, side view,
only thumbs and upper fingers visible from below, holding a sheet,
muted desaturated skin, thin black outline, chunky pixel art, no color background,
simple readable silhouette
```

- 파라미터: 배경 제거 켬. 좌우 대칭은 한쪽 생성 후 미러 가능
- 대안: 생성 난이도가 높으면 파이썬 생성 엄지(현행)를 유지한다

## 3. 노드 인상 아이콘 6종 (nodes)

- 유형: UI 아이콘 / 최종 크기: 16x16 (생성 48x48 후 다운스케일) / 배경 제거 켬
- 상태: 대기
- 공통 접미: `monochrome black sumi ink brush symbol, old map annotation mark, bold simple silhouette, no color, chunky pixel art, thick outline, plain background`

| 파일 | 인상 | 대상 | 프롬프트 핵심 |
|---|---|---|---|
| danger | 위험 (전투) | 교차한 칼 | two crossed swords |
| peril | 매우 위험 (중간보스) | 해골 | a human skull, empty eye sockets |
| unknown | 알 수 없음 (이벤트/내기) | 물음표 | a single question mark |
| boon | 좋음 (상점/쉼터) | 여의주 | a shining wish-fulfilling pearl with small rays |
| mystery | 신비 (신당) | 초승달 | a crescent moon with a tiny star |
| boss | 보스 (막 보스) | 도깨비 얼굴 | fierce korean dokkaebi face, big brows, fangs, topknot, NO horns, NO oni |

- 고증 주의(ART_STYLE 2장): 보스 아이콘은 뿔과 오니 조형 금지. 사람 형상의 험상궂은 도깨비 얼굴로 표현한다
- 판정 기준: 16px 축소 후에도 실루엣이 읽히는지, 완전 무채색인지, 6종이 서로 구분되는지(특히 매우 위험 해골과 보스 얼굴)

## 아이콘 개정 방향 (2026-08-04, 진행 중)

- 1차 PixelLab 격자(칼/해골/물음표/보주/초승달/도깨비 얼굴)는 너무 직역적이라 낡아 보여 기각
- 2차 은유안(할퀸 자국/안개/매듭/별자리/눈)은 방향은 맞으나 계속 개정
- 신규 방향(사용자): 조선 독도법(옛 군현지도 기호법) 채용 검토. 지도에 실제로 쓰던 기호로 인상을 대체한다
  - 위험(전투): 봉수(烽燧) 하나 (경보 신호)
  - 매우 위험(중간보스): 봉수 둘 이상 (높은 경보)
  - 알 수 없음(이벤트/내기): 미상(未詳) 빈 방소 또는 안개 처리
  - 좋음(상점/쉼터): 역참/주막 기호 (보급과 휴식)
  - 신비(신당): 사찰/신당 기호 (卍 만자는 오해 소지로 금지, 당간이나 삼문 형태)
  - 보스(막 보스): 읍성(邑城) 성곽 기호 (본거지). 레퍼런스 map_old_gojido의 중앙 방형 읍성 참조
- 확정 전까지 코드 드로잉 임시 아이콘 유지. 확정 후 PixelLab 마감 또는 먹선 직접 제작

## 배치 (2026-08-04)

- 노드를 일직선 격자로 두지 않는다. 시드 기반 결정적 지터로 삐뚤빼뚤하게 배치한다(손으로 그린 옛 지도 느낌). node_map.gd _compute_layout의 JITTER_X 6, JITTER_Y 9

## 후처리 (S2)

- 명령 예: `python3 tools/pipeline/postprocess.py in.png --out out.png --size 16` (아이콘), 배경은 크기 유지
- 배치: 배경 assets/sprites/ui/map_paper.png, 아이콘 assets/sprites/ui/nodes/{danger,peril,unknown,boon,mystery,boss}.png

## 결과 (2026-08-04)

- 배경+손 채택: "양손으로 펼쳐 든 옛 지도" 일체형 1장 (480x272, Create S-XL image Pro, 배경 제거 끔). 손, 소매(흰 커프), 종이, 산수(상단 산, 모서리 소나무, 가운데 물길)가 한 스타일. 사용자 승인
  - 교훈: 손을 별도 요소로 뽑아 합성하면 스타일이 따로 논다(1차 기각). 손과 종이를 한 장으로 생성하는 것이 정답
- 배경 단독안 2종(산수 적은 담백안, 산수 많은 고지도안)은 후보 기록만. 손 일체형으로 대체됨
- 아이콘 1차(칼/해골/물음표/보주/초승달/도깨비 얼굴, 192x128 격자): 직역적이라 기각(사용자: 낡아 보임)
- 아이콘 2차(먹 표식 은유: 할퀸 자국/안개/매듭/별자리/눈): 코드 제작, 임시 채택. 무채색 방표(동람도식 세로 팻말) 안에 먹 문양으로 표시. 독도법 기호안(봉수/역참/읍성)으로 개정 계속
- 색 규칙 확정: 지도 화면은 완전 무채색(먹 + 종이색). 방표 색 채움 금지. 구분은 테 모양으로(현재=이중 테, 선택 가능=점선 테)
- 슬더스 변주 확정: 거점 간 상시 연결선을 긋지 않는다. 현재 위치에서 갈 수 있는 곳으로만 굽은 먹 발자취를 찍는다
- 소모: 배경 2회(각 25), 아이콘 격자 1회(20), 손 단독 1회(20, 기각), 손+지도 일체 1회(40) = 약 130 generations
- 남은 작업: 사용자가 PixelLab 갤러리에서 손+지도 일체본 다운로드 -> art_src/generated/pixellab/ 이동 -> assets/sprites/ui/map_paper.png 배치(Claude). 독도법 아이콘 시안

## 검토 중 (게임 디자인, 결정 보류)

- 사용자 제안: 노드 자유 이동 + 시간 예산제. 다음 노드 선택에 제한을 두지 않되 거리에 따라 소요시간(1/2)을 소모하고, 막 보스까지의 총 시간은 고정(명계 체류 패널티). 긍정 노드는 서로 멀리 배치해 거리=대가 구조로
- Claude 의견(2026-08-04): 찬성. 생기 몰림(미시)과 같은 축의 거시 긴장, 슬더스와 구조적 차별화, 1막 "달이 기운다" 연출과 정합(남은 시간=달 위치). 단 보스 직행 악용은 관문(중간보스)으로, 재방문은 지도 이동만(방 재플레이 없음)으로, 검증은 10장 DP에 시간 차원 추가로 대응
- RUN_STRUCTURE 2/3/4장(층 DAG)과 충돌하는 대형 결정이라 DECISIONS 기록과 RUN_STRUCTURE 개정 후 진행한다. 사용자 확정 대기
