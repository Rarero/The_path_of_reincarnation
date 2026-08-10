# 환생길 — 효과음(SFX) 최종 확정본

2026-08-10 확정. 최종 효과음은 아래 **3종**이다.

| # | 항목 | 확정 파일 | 길이 |
|---|------|-----------|------|
| 1 | 플레이어 피격음 | `output/sfx/01_player_hit_v3.wav` | 0.13~0.18초 |
| 2 | 몬스터 피격음 | `output/sfx/02_monster_hit_v1.wav` | 0.51초 |
| 3 | 이동/선택 버튼음 (맵 이동 + 메뉴 겸용) | `output/sfx/05_map_select_v1.wav` | 0.15초 |

제외 항목: 스테이지 클리어음(여러 방향 시도 후 사용자 결정으로 제외),
미니게임 연타음(제외). 30초 원본 클립은 `output/sfx/raw/`에 보관되어 있어
필요 시 언제든 재추출·재생성 가능.

---

## 생성 방식 (재생성 시 참고)

Lyria 3 clip 모델은 **30초 고정 출력**이라 짧은 효과음을 직접 생성할 수 없다.
채택한 파이프라인:

1. "같은 효과음을 무음 간격으로 반복" 스캐폴드를 붙여 30초 클립 생성
2. ffmpeg + numpy 로 무음 기준 소리 덩어리 탐지 (10ms RMS, -35dB 임계)
3. 첫 어택 후 감쇠 지점에서 조기 컷, 최대 1초 제한, 페이드/노멀라이즈
4. 44.1kHz 16bit 모노 WAV 저장, 항목당 변형 3개씩 생성 후 선택

핵심 노하우 (실측):
- "소리 하나 + 나머지 무음" 프롬프트는 모델이 무시함 → 반드시 반복 스캐폴드 사용
- 묵직한 저음 타격은 잔향이 붙어 길어짐 → **"dry foley one-shot, dead studio
  room, heavily damped, no reverb/tail"** 강조로 타이트한 원샷 확보
- 육성('악!')이 필요하면 `instrumental=False` + 무술 기합(kiai) 프레이밍이 안정적

---

## 1. 플레이어 피격음 (`01_player_hit`, one_shot, max 1초)

묵직한 저음의 몸통 타격 한 방. 뺨/채찍 같은 高음 스냅 금지.

```
Recorded as a dry foley one-shot sample in a dead studio room: one extremely
tight deep punch impact on a heavy body, a massive low-end thump that stops
almost immediately, heavily damped, no reverb, no echo, no tail, no bounce,
not a slap, not a whip, shorter than half a second
```

## 2. 몬스터(도깨비) 피격음 (`02_monster_hit`, one_shot, max 1초)

타격 쾌감이 느껴지는 묵직하고 깔끔한 완전 타격음.

```
A monster taking a powerful hit in a 2D action game: one deep meaty smack
with a crisp sharp attack, like a heavy strike landing perfectly, punchy and
instantly satisfying arcade hit feel, single monotone impact with no pitch
bend, short and clean
```

## 3. 이동/선택 버튼음 (`05_map_select`, one_shot, max 1초)

한지 지도에서 다음 경로를 고르는 촉감형 소리. 맵 이동 선택음이자
초기 화면 메뉴 클릭/이동음으로 겸용.

**레퍼런스 이미지**: `07_map/map_select_screen.png` (손에 든 낡은 한지 지도)

```
A map node selection sound for choosing the next route on an old hanji paper
map held in the hands, like the reference image: a soft paper rustle combined
with a gentle wooden stamp thock and a faint ink-brush swish, tactile and
short
```
