# 환생길 — 화면별 BGM 시스템 프롬프트

게임: **환생길** (가제: 저승 초입에서)
스토리: 현생을 살다 죽은 회사원이 저승 차사를 만나고, 저승의 문턱들을 넘으며 도깨비 던전을 클리어하는 한국 저승 판타지 픽셀아트 게임.

모델: Google **Lyria 3** (Vertex AI 경유, `generateContent`)
- 1차 생성: `lyria-3-pro-preview` + **곡 길이 약 1분 30초** (데모 게임 기준, 프롬프트로 길이 지시)
- 빠른 스케치용: `lyria-3-clip-preview` (30초 고정)
- WAV 출력은 pro 모델 전용 (기본 MP3)

공통 원칙:
- 모든 트랙 **Instrumental only** (보컬 없음), 게임 루프에 적합한 시작/끝
- 전체적으로 "너무 어둡지 않게" — 저승이지만 포근하고 신비로운 톤 유지
- **보스전만 예외적으로 가장 긴박하고 격렬하게**
- 한국 전통 악기(대금, 가야금, 해금, 태평소, 사물놀이 타악)를 화면 성격에 맞게 배합

---

## 1. 게임 시작 화면 (타이틀)

**레퍼런스 이미지**: `00_overview/ingame_screenshot_20260810.png`

**이미지 분석**: 황혼 무렵 저승 초입의 한옥 상점가. 등불이 켜진 거리에 반투명한 영혼들이
평화롭게 거닐고, 멀리 사찰로 오르는 계단이 보인다. 쓸쓸하면서도 포근하고 신비로운 첫인상.

**음악 방향**: 느린 앰비언트 + 한국 전통 선율. 게임의 정서(죽음이지만 따뜻함)를 30초 안에 각인.

**시스템 프롬프트**:
```
Instrumental only, no vocals. Game title screen BGM for a Korean afterlife
fantasy pixel-art game. A calm, mysterious ambient piece blending Korean
traditional instruments: breathy daegeum (bamboo flute) melody, soft gayageum
plucks, an occasional distant temple bell, over warm ambient pads. Slow tempo
around 62 BPM, minor pentatonic feel. Mood: wistful yet welcoming, like the
lantern-lit streets of a quiet village between life and death at dusk, with
spirits strolling peacefully. Gentle dynamics, seamless loop-friendly ending,
subtle reverb like cool night air.
```

---

## 2. 스토리 화면 (인트로 7컷)

**레퍼런스 이미지**: `01_intro/intro_p1_office.png` ~ `intro_p7_resolve.png` (7장 전부 입력)

**이미지 분석**: ① 심야 사무실의 지친 회사원 → ② 새벽 횡단보도 → ③ 트럭 헤드라이트(사고)
→ ④ 갓을 쓴 저승차사와의 첫 대면 → ⑤ 명부를 다시 읽으며 당황하는 차사(실수) →
⑥ "환생대기줄, 약 300년 소요" 팻말 앞 유령 행렬 → ⑦ 궁궐로 이어지는 거대한 계단 앞의 결의.

**음악 방향**: 서사형 시네마틱. 쓸쓸한 도입 → 신비한 전개 → 담담한 결의로 감정 아크를 따라감.

**시스템 프롬프트**:
```
Instrumental only. Cinematic story-scene music for the opening chapter of a
Korean folklore fantasy game, following the emotional arc of these seven
scenes in order: weary late-night city routine, a quiet crosswalk at dawn, a
sudden bright flash, a solemn meeting with a mysterious robed official in a
traditional Korean hat, his sheepish apology over a ledger mistake, a long
waiting line stretching for centuries, and a resolute walk toward a grand
staircase. Begin with sparse melancholic felt piano over quiet city-night
ambience, let warm strings and a breathy daegeum enter as the mysterious
world appears, add gentle humor and wonder in the middle, and end with quiet,
hopeful determination. Around 72 BPM, bittersweet but never frightening,
emotional and story-driven.
```

**세이프티 필터 주의사항** (실측 결과):
- "dies in a traffic accident" 등 죽음/사고 직접 표현 → 즉시 차단(PROHIBITED_CONTENT)
- 완곡 표현이라도 afterlife/grim reaper/reincarnation 등 민감 단어가 **7컷 이미지 시퀀스와
  결합**되면 차단됨 (텍스트 단독·이미지 단독·이미지 1~4장 조합은 각각 통과 → 총합 임계치 방식)
- 해결: 스토리 서사를 장면 묘사 + 음악 지시 중심으로 순화한 위 프롬프트는 이미지 7장과
  함께 3회 연속 통과 확인

---

## 3. 던전 입장 전 허브 (차사 상점)

**레퍼런스 이미지**: `02_hub/2026-08-10 11_09_43.068.png`

**이미지 분석**: '차사 아무개' NPC가 지키는 저승 상점 내부(사이드뷰). 두루마리와 상자가
쌓인 선반, 홍등 하나, 보랏빛의 차분한 색조. 대화하고 무기를 받는 안전한 준비 공간.

**음악 방향**: 아늑한 상점 테마. 낮은 에너지, 안전지대의 느긋함 + 저승 특유의 옅은 신비.

**시스템 프롬프트**:
```
Instrumental only. Cozy shop and hub theme for an underworld general store run
by a friendly grim reaper clerk, where the hero chats with NPCs and receives
weapons before entering the dungeon. Relaxed, warm, slightly whimsical:
plucked gayageum and soft haegeum melodies over a mellow lo-fi beat, gentle
wooden percussion, small hand bells. Around 78 BPM, low-medium energy, a safe
and unhurried atmosphere with a faint mysterious afterlife tint, like a dim
lantern-lit interior in purple tones. Seamless loop-friendly.
```

---

## 4. 던전 스테이지 (도깨비 야시장)

**레퍼런스 이미지**: `03_stage/2026-08-10 11_09_59.105.png`

**이미지 분석**: 보름달 아래 색색의 초롱이 걸린 야시장 축제 거리. 노점 사이로 도깨비들이
섞여 있고 전투 UI(전투 시간, 생기)가 표시된 사이드스크롤 액션 스테이지. 흥겨움+가벼운 긴장.

**음악 방향**: 놀이패 같은 리드미컬 액션. 어둡지 않게, 축제의 흥과 전투의 추진력을 동시에.

**시스템 프롬프트**:
```
Instrumental only. Action stage BGM for side-scrolling battles through a
moonlit night-market festival street full of mischievous Korean goblins
(dokkaebi). Playful-spooky and energetic: driving samulnori-inspired
percussion with janggu and buk grooves and kkwaenggwari accents, a catchy
taepyeongso-style lead melody, bouncy bass line. Around 118 BPM, full-moon
festival vibe with colorful lanterns — fun and lively with light tension,
never gloomy or scary. Seamless combat loop.
```

---

## 5. 이벤트 스테이지 (미니게임)

**레퍼런스 이미지**: 없음 (텍스트 프롬프트만 사용)

**컨셉**: 던전 중간의 미니게임. 분위기를 확 반전시키는 코믹하고 리듬감 있는 트랙.

**음악 방향**: 리듬게임처럼 박자가 또렷한 하이 에너지 파티 트랙. 사물놀이 + 칩튠 퓨전.

**시스템 프롬프트**:
```
Instrumental only. Upbeat minigame BGM that completely flips the dungeon mood:
a comedic, rhythm-heavy party track for a goblin minigame. Quirky and bouncy:
fast samulnori percussion groove fused with chiptune-style synth stabs, hand
claps, call-and-response phrases between instruments, playful pentatonic
hooks. Around 132 BPM, high energy, cheerful and mischievous, with a crisp
steady beat perfect for a timing-based rhythm minigame. Tight seamless loop.
```

---

## 6. 신당 (능력 획득 장소)

**레퍼런스 이미지**: `05_shrine/2026-08-10 11_10_28.763.png`

**이미지 분석**: 보름달 밤, 돌장승과 석상이 지키는 고요한 신당. 홍살문 형태의 문, 몬스터가
없는 안식처이자 산신의 권능을 얻는 신성한 공간.

**음악 방향**: 명상적이고 신성한 정적. 타악 없이 공간감 위주, 경외감과 따뜻함.

**시스템 프롬프트**:
```
Instrumental only. Sacred shrine theme for a quiet moonlit sanctuary guarded
by stone statues, where the hero receives blessings and new powers from a
mountain spirit; there are no enemies here. Serene and mystical: long breathy
daegeum phrases, sparse gayageum harmonics, soft wind chimes, one deep temple
bell, and airy drone pads like night wind through pines. Very slow, around 54
BPM, spacious and reverent with wide reverb, meditative yet gently warm, full
of quiet awe under the full moon. No percussion, loop-friendly.
```

---

## 7. 보스몹 스테이지 (최고 긴박)

**레퍼런스 이미지**: 없음 (텍스트 프롬프트만 사용)

**컨셉**: 게임 전체에서 가장 긴박한 트랙. 도깨비 던전 최심부의 보스전.

**음악 방향**: 사물놀이 대북 + 오케스트라 하이브리드, 태평소 리드. 빠르고 무자비한 추진력.

**시스템 프롬프트**:
```
Instrumental only. The most intense boss battle BGM of the game: the final
confrontation deep inside the goblin dungeon of the Korean underworld. Urgent,
fast and relentless: pounding hybrid of heavy samulnori drums (buk, janggu)
with orchestral toms and taikos, a shrieking taepyeongso lead trading phrases
with aggressive staccato strings, ominous low brass hits, driving double-time
rhythm around 155 BPM in a dark minor key. Rising tension, dramatic accents,
short breakdowns that explode back even harder — epic Korean shamanic-ritual-
meets-boss-fight energy. Seamless high-intensity combat loop.
```

---

## 생성 파일 매핑

| # | 화면 | 프리셋 키 | 출력 파일 |
|---|------|-----------|-----------|
| 1 | 게임 시작 화면 | `00_title` | `output/bgm/00_title.mp3` |
| 2 | 스토리 화면 | `01_story` | `output/bgm/01_story.mp3` |
| 3 | 던전 입장 전 허브 | `02_hub` | `output/bgm/02_hub.mp3` |
| 4 | 던전 스테이지 | `03_stage` | `output/bgm/03_stage.mp3` |
| 5 | 이벤트 미니게임 | `04_event` | `output/bgm/04_event.mp3` |
| 6 | 신당 | `05_shrine` | `output/bgm/05_shrine.mp3` |
| 7 | 보스몹 스테이지 | `06_boss` | `output/bgm/06_boss.mp3` |
