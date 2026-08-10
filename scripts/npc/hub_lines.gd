class_name HubLines
extends RefCounted

## 허브 NPC 대사 데이터 (docs/DESIGN_HUB.md 5.7절 확정 대사).
##
## hub.gd에 두지 않고 분리한 이유는 대사가 20줄을 넘어 씬 스크립트가 콘텐츠
## 파일이 되기 때문이다. DESIGN_INTRO 5장 선례를 따라 지금은 스크립트 상수로
## 두고, 콘텐츠가 더 커지면 커스텀 리소스(.tres)로 이관한다.
##
## 대사 한 줄: { speaker, text, effect }
## 대화 하나: { id, lines, skippable }
## effect는 그 줄이 뜨는 순간의 지급 훅이고, 대화 완료 시 세울 플래그는
## 호출자(hub.gd)가 대화 id로 판단한다.

const CHASA: String = "차사"
const CLERK: String = "접수 관원"
const SMITH: String = "대장장이 도깨비"

## 첫 런 진입 직후 1회 띄우는 호출 토스트 (5.3절). 대화 상자가 아니라 토스트다
const CHASA_CALL: String = "차사: 어이, 잠깐."

## 차사 첫 대화. 게이팅이며 건너뛸 수 없다. 마지막 줄에서 환도를 준다.
## 사용자가 지정한 3단계를 2줄씩 묶었고, 첫 줄이 오프닝 7페이지에서 끊긴
## 차사의 말("거긴 함부로 가는 데가—")을 잇는다.
const CHASA_INTRO: Dictionary = {
	"id": "chasa_intro",
	"skippable": false,
	"lines":
	[
		{"speaker": CHASA, "text": "…거긴 함부로 가는 데가 아니라니까.", "effect": ""},
		{"speaker": CHASA, "text": "염라대왕님 앞까지 가겠다고? 여기서 대전까지 세 고비다.", "effect": ""},
		{"speaker": CHASA, "text": "가다 죽어도 자넨 명부에 없어. 도로 이 창고로 실려 온다.", "effect": ""},
		{"speaker": CHASA, "text": "난 여기서 기다리지. 자네가 포기하겠다고 할 때까지.", "effect": ""},
		{"speaker": CHASA, "text": "…그래도 내 실수로 온 거니까. 이거라도 가져가라.", "effect": ""},
		{"speaker": CHASA, "text": "창고 정리하다 나온 거다. 없어진 줄도 모를 거야.", "effect": "grant_sword"},
	],
}

## 차사 상시 순환 (4종). 직전에 나온 것은 연속으로 다시 나오지 않는다
const CHASA_IDLE: Array = [
	"장부는 줄지를 않아. 자네 건은 여전히 미결이고.",
	"특수창고 선반이 또 무너졌다. 자네 자리도 거기 어디쯤이야.",
	"돌아왔군. 놀랍지도 않다.",
	"쉬어라. 어차피 문은 안 닫힌다.",
]

## 차사 진행도 해금 (4종, 1회성). runs는 run_count 임계값이다
const CHASA_MILESTONES: Array = [
	{"id": "chasa_r10", "runs": 10, "text": "열 번. 내가 자네 이름을 잘못 읽은 대가치고는 길다."},
	{"id": "chasa_r6", "runs": 6, "text": "여섯 번이면 보통 접수 줄로 돌아온다. 자넨 안 그러는군."},
	{"id": "chasa_r3", "runs": 3, "text": "…셋. 세고 있었다. 딱히 관심이 있어서는 아니고."},
	{"id": "chasa_r1", "runs": 1, "text": "봐라. 말했잖나. 도로 실려 온다고."},
]

## 차사 사건 반응 (2종, 1회성). 사건 플래그 연결은 D10과 G7 범위이며
## 그 전까지 hub.gd는 이 목록을 건너뛴다 (5.6절)
const CHASA_EVENTS: Array = [
	{"id": "chasa_boss1", "flag": "boss_act1_cleared", "text": "시장 문지기를 넘었다고? …도장은 아직 멀었다."},
	{"id": "chasa_smith", "flag": "npc_blacksmith", "text": "그 도깨비를 데려왔나. 시끄러워지겠군."},
]

## 접수 관원 지도 지급. 건너뛸 수 없고 마지막 줄에서 지도를 준다.
## 이동 규칙의 핵심 한 줄(길은 자유, 대가는 명줄)을 여기서 한 번 박아 둔다.
## 나머지는 다시 말을 걸어야 나온다 (5.5절)
const CLERK_MAP: Dictionary = {
	"id": "clerk_map",
	"skippable": false,
	"lines":
	[
		{"speaker": CLERK, "text": "상행 접수요? …기록은 안 하겠소. 접수하면 줄부터 서야 하니까.", "effect": ""},
		{"speaker": CLERK, "text": "시장 약도요. 길은 알아서 고르시오. 대신 걸음마다 명줄이 닳소.", "effect": ""},
		{"speaker": CLERK, "text": "기호 뜻은 지도에 다 적혀 있소.", "effect": "grant_map"},
	],
}

## 접수 관원 이동 규칙 설명. 반복 가능하며 건너뛸 수 있다.
## 자유 이동과 명줄 예산 (docs/RUN_STRUCTURE.md 11장). 규칙은 다섯이고 한 줄에
## 하나씩만 담는다. 친절하게 풀어 설명하지 않는다. 이 관원은 접수를 피하는 자다
const CLERK_ROUTE: Dictionary = {
	"id": "clerk_route",
	"skippable": true,
	"lines":
	[
		{"speaker": CLERK, "text": "길 말이오? 아무 데나 가시오. 나는 안 막소.", "effect": ""},
		{"speaker": CLERK, "text": "이어진 곳이면 어디로든 가시오. 왔던 길을 되짚어도 좋소.", "effect": ""},
		{"speaker": CLERK, "text": "대신 걸음마다 명줄이 닳소. 먼 걸음일수록 많이 닳소.", "effect": ""},
		{"speaker": CLERK, "text": "되짚는 걸음도 값은 같소. 다만 밟았던 자리엔 아무것도 없소.", "effect": ""},
		{"speaker": CLERK, "text": "다 닳아도 못 가게 하진 않소. 저승 것들이 산 자인 줄 알아볼 뿐이오.", "effect": ""},
		{"speaker": CLERK, "text": "아껴도 소용없소. 남은 명줄은 문 앞에서 없어지오.", "effect": ""},
	],
}

## 접수 관원 마크 설명. 반복 가능하며 건너뛸 수 있다.
## 정본은 지도 화면 안 범례이고 이 대화는 어디서 보는지만 알려준다 (5.5절)
const CLERK_MARKS: Dictionary = {
	"id": "clerk_marks",
	"skippable": true,
	"lines":
	[
		{"speaker": CLERK, "text": "기호 뜻은 지도를 펼치면 볼 수 있소. 여는 법은 화면 아래에 적어 뒀소.", "effect": ""},
		{"speaker": CLERK, "text": "예감 막대는 좋고 나쁨의 비율이지 결과가 아니오. 그건 나도 모르오.", "effect": ""},
	],
}

## 지도를 받은 뒤 반복 설명 순서. 이동 규칙을 먼저 낸다. 갓 지도를 받은 참이라
## 알아야 할 것이 길 고르는 법이지 기호 범례가 아니다
const CLERK_EXPLAIN: Array = [CLERK_ROUTE, CLERK_MARKS]

## 대장장이 총 해금. 해금형 NPC라 대장장이 자체를 데려온 뒤에만 열린다.
## 마지막 줄에서 총이 풀린다 (docs/systems/WEAPONS.md 11.2절 세 진입로 중 대장장이 해금).
## 주인공의 군필 설정이 총을 다룰 줄 아는 근거다 (docs/GDD.md 2장)
const SMITH_GUN: Dictionary = {
	"id": "smith_gun",
	"skippable": false,
	"lines":
	[
		{"speaker": SMITH, "text": "네놈 짐에서 쇳덩이가 하나 나왔다. 이승 물건이지?", "effect": ""},
		{"speaker": SMITH, "text": "화약 냄새가 나더군. 여기선 아무도 못 고치는 물건이라 내가 봐줬다.", "effect": ""},
		{"speaker": SMITH, "text": "가져가라. 칼이 손에 안 맞거든 이걸 들어.", "effect": "unlock_gun"},
	],
}

## 대장장이 시작 무기 선택. 해금 이후 다시 말을 걸면 환도와 총을 번갈아 고른다 (11.3절).
## 고르는 순간 바뀌므로 대화 자체가 곧 교체다
const SMITH_SWAP: Dictionary = {
	"id": "smith_swap",
	"skippable": true,
	"lines": [{"speaker": SMITH, "text": "바꿔 주랴. 뭘 들고 나갈지는 네가 정해라.", "effect": "swap_weapon"}],
}

## 접수 관원 상시 순환 (2종)
const CLERK_IDLE: Array = [
	"다음 분… 아, 아직 자네군.",
	"번호표는 뽑지 마시오. 뽑으면 줄에 서야 하오.",
]


## 한 줄짜리 대화를 만든다. 순환과 해금 대사가 쓴다.
static func single(id: String, speaker: String, text: String) -> Dictionary:
	return {
		"id": id,
		"skippable": true,
		"lines": [{"speaker": speaker, "text": text, "effect": ""}],
	}
