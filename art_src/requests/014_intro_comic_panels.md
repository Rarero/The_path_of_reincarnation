# 에셋 요청서: intro_comic_panels

작성: 2026-08-03 (프론트엔드 세션)
근거 문서: docs/DESIGN_INTRO.md 4장(오프닝 7페이지 스크립트), docs/ART_STYLE.md
용도: 오프닝 컷신의 정적 일러스트 패널. 미국 컷툰(패널 분할) 연출

## 기본 정보

- 에셋 이름: intro_panel_01 ~ intro_panel_07 (페이지별, 페이지당 1~3컷)
- 유형: 컨셉아트 (컷툰 일러스트)
- 최종 크기: 320x180 화면에 얹히는 패널. 페이지 내 1~3분할
- 팔레트: 야간 도입은 침전 한색, 접수청 등장부터 황혼 관청 톤
- 상태: 생성 완료, 임포트 대기 (7컷 채택, 2026-08-03)

## 생성 설정 (S1, PixelLab)

- 도구: PixelLab 범용 생성 (일러스트 품질)
- 고정 헤더 (ART_STYLE 9장): SCALE 16px=1m, REFERENCE Skul 비례, VIEW 장면별, PIXEL 저해상 가독성, LIGHT 장면별
- 페이지별 SUBJECT (docs/DESIGN_INTRO.md 4.2와 1:1):
  1. office: 야심한 사무실에 홀로 남은 직장인, 이어서 텅 빈 밤거리로 나오는 뒷모습
  2. crosswalk: 신호를 기다리는 인물, 초록 신호, 뒤에서 다가오는 세 개의 말풍선(이름 판독 불가)
  3. truck: 뒤돌아보는 얼굴 클로즈업, 측면에서 쏟아지는 트럭 헤드라이트(끝에 화이트 아웃)
  4. saja: 눈뜬 시야에 화려한 관복의 저승사자가 머리를 짚고 내려다봄
  5. mistake: 명부를 대조하며 식은땀 흘리는 저승사자, 이름 불일치 표식
  6. queue: 끝없는 민원 대기줄과 번호표, 먼지 쌓인 특수창고 팻말
  7. resolve: 위로 뻗은 길과 먼 염라대전 실루엣, 소매 걷고 돌아서는 뒷모습

- 우선 제작: 3(truck), 4(saja). 나머지 후속
- 공통 프롬프트 골격:

```
Korean webcomic style pixel-art illustration panel, cinematic composition,
modern Korean office worker protagonist (rolled-up white shirt, loose tie, slacks),
[SUBJECT per page],
painterly pixel-art, strong readable silhouettes, night to dusk lighting, low contrast solemn-yet-wry mood
```

- 저승사자(차사) 고증 지시:

```
Korean traditional afterlife messenger (chasa) in colorful old official attire:
red official robe (hongcheollik), black wide-brim official hat (jeonrip) with tassel, sash,
NOT a black hooded death robe, NOT japanese shinigami
```

- 네거티브 프롬프트:

```
japanese oni, horns, black death robe, grim reaper hood, scythe, japanese shinigami,
torii, kanji, hiragana, katakana, chinese palace, chinese red lantern,
photorealistic, 3d render, watermark, readable signboard text
```

- 주요 파라미터: 페이지별 1~3 패널을 한 장 합성 또는 개별 컷 생성. 판독 불가 이름은 흐린 말풍선으로
- 채택 결과 (2026-08-03): PixelLab Create S-XL image (Pro), 688x384(16:9), 배경 제거 끔. 7페이지 각 1컷 채택. 차사는 채택본(검은 갓, 검은 두루마기). 각 1회 생성으로 채택(반복 없음)

## 후처리 (S2)

- 패널 분할과 캡션 여백은 인게임에서 처리(스켈레톤 PanelFrame 대체). 일러스트 원본만 납품

## 결과

- 최종 파일: assets/sprites/intro/intro_p1_office.png ~ intro_p7_resolve.png (688x384). intro.gd의 페이지별 tex 슬롯에 연결, intro.tscn ArtImage(TextureRect)로 표시
- 메모: 3페이지 화이트 아웃은 코드 플래시와 연동되므로 컷 끝을 밝게 마감한다
