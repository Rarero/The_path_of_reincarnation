# 에셋 요청서: frontend_title_bg

작성: 2026-08-03 (프론트엔드 세션)
근거 문서: docs/DESIGN_INTRO.md 3장, docs/ART_STYLE.md
용도: 타이틀 화면 배경 키비주얼. 게임 첫 화면의 인상을 정한다

## 기본 정보

- 에셋 이름: title_bg
- 유형: 배경 (키비주얼)
- 최종 크기: 320x180 기준 화면 채움 (생성은 고해상도 후 다운스케일)
- 팔레트: 접수청 서브 팔레트(황혼빛 관청). 시장 난색과 구분. 미확정 시 자유 후 추출
- 상태: 생성 완료, 임포트 대기 (2026-08-03 채택)

## 생성 설정 (S1, PixelLab)

- 도구: PixelLab 범용 생성 또는 배경 생성
- 스타일 레퍼런스: docs/ART_STYLE.md 기준 (Skul 비례, 야간 조명 톤). style_refs 무드 앵커 참고
- 고정 헤더 (ART_STYLE 9장 카드): SCALE 16px=1m, REFERENCE Skul 톤, VIEW 정측면 원경, PIXEL 굵은 픽셀 제한 팔레트, LIGHT 황혼 역광
- 프롬프트:

```
Korean afterlife entrance reception at dusk, side-scrolling game title key visual,
an old wooden administrative office of the underworld (jeoseung), tiled low roofs and paper-covered windows,
a queue of faint wandering souls waiting at service windows, stacked ledgers and paper stamps,
to one side a dim storage annex with dusty shelves and hanging name tags,
a long path leading upward into the far background toward a distant palace silhouette,
muted twilight palette of faded indigo, ash grey and dim amber lantern glow, low contrast solemn mood,
Joseon dynasty government office architecture, painterly pixel-art oriented concept art, 16:9 horizontal composition,
left side kept calmer for menu buttons overlay
```

- 네거티브 프롬프트:

```
japanese oni, horns, black death robe, japanese shinigami, torii, kanji, hiragana, katakana,
chinese red lanterns, chinese palace, bright daylight, blue sky, neon, cyberpunk, modern signage,
readable text, watermark, red dominant palette, cluttered left side, character close-up
```

- 주요 파라미터: 16:9, 고해상도 생성 후 320x180 화면 기준 다운스케일. 좌측 하단은 버튼 오버레이 영역이라 비워 둔다
- 채택 결과 (2026-08-03): PixelLab Create S-XL image (Pro), 688x384(16:9), 배경 제거 끔. 황혼빛 관청 거리, 원경 염라대전 실루엣, 등불, 떠도는 혼. 1회 생성 채택

## 후처리 (S2)

- 팔레트 추출로 접수청 서브 팔레트 초안 생성 (art_src/palettes/). 배경 자체는 컨셉 단계라 큰 후처리 없음

## 결과

- 최종 파일: assets/sprites/ui/title_bg.png. main_menu.tscn에 TitleBg(TextureRect, keep_aspect_covered)로 Background ColorRect 위에 배치
- 메모: 가제 로고 확정 시 로고 배치 여백을 상단 또는 좌상단에 확보한다
