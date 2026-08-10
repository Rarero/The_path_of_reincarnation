# 프론트엔드 캐릭터 아트 인박스 (PixelLab)

2026-08-03 생성. 도구: PixelLab Create S-XL image (Pro). 크기 64x64, 4x4 그리드(16변형), 배경 제거.
각 그리드 PNG는 256x256이며 64x64 셀 16개로 구성된다. 톤앤매너는 접수 관원 프레임을 스타일 레퍼런스로 걸어 통일했다.

## 배치 목록

| 권장 파일명 | 내용 | 게임 용도 | 상태 |
|---|---|---|---|
| saja_jeoseung_grid.png | 검은 갓, 검은 두루마기, 창백하고 피곤한 저승사자(두루마리 소지) | 오프닝 저승사자 + 허브 실수한 차사 | Downloads |
| gwanwon_reception_grid.png | 청회색 과로 관원, 다크서클, 서류 더미 | 허브 접수 관원(신규 NPC) | Downloads |
| gwanwon_pangwan_grid.png | 붉은 관복 관원 | 3막 판관, 저승 관리 계열 | Downloads |
| saja_gamjae_grid.png | 감재사자도 기반 화려한 무장 저승사자(깃털 관모, 소환장) | 특수 또는 보류(후보) | PixelLab 갤러리 |

## 사용자 수행 필요

1. Downloads의 최근 PixelLab PNG 3개를 위 권장 파일명으로 바꿔 이 폴더(art_src/generated/pixellab/frontend/)에 넣는다.
2. saja_gamjae_grid.png는 보류다. 필요해지면 PixelLab 갤러리에서 다시 내려받아 같은 이름으로 넣는다.
3. 넣은 뒤 알려주면 Claude가 분할과 씬 연결을 이어서 수행한다.

## 이후 Claude 작업 (파일 배치 후)

- 각 그리드를 64x64 셀 16개로 분할하고 채택 셀을 고른다.
- tools/pipeline/postprocess.py로 후처리(팔레트, 알파).
- assets/sprites/npc/에 배치하고 hub.tscn의 NPC 플레이스홀더(ColorRect)를 실제 스프라이트로 교체한다. 실수한 차사는 저승사자, 접수 관원은 신규 NPC로.
- docs(DESIGN_HUB 4장 NPC 표, GDD 8장)에 접수 관원과 실수한 차사=저승사자 반영.

## 고증 참고

- 감재사자도(監齋使者圖). 조선. 국립중앙박물관 소장품번호 구2254. 종이 불화. 공공누리 출처표시. 화려한 복장 저승사자 도상의 근거. 참조: https://www.museum.go.kr/MUSEUM/contents/M0502000000.do?schM=view&searchId=search&relicId=7961
- 최종 채택 저승사자는 감재사자도의 화려 무장형이 아니라, 검은 갓과 검은 두루마기의 전형적 저승사자에 캐스트 톤을 맞춘 방향으로 확정.
