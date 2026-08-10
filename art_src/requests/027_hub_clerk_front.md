# 에셋 요청서: 접수 관원 (창구 정면)

## 기본 정보

- 에셋 이름: npc_clerk_front
- 유형: 캐릭터
- 최종 크기: 프레임 24x40 (인게임 인물 폭 23 이하, 키 34 이하)
- 팔레트: art_src/palettes/act1_night_draft.gpl
- 상태: 임포트 완료

## 배경

허브 접수청 창구 안에 서는 NPC다. 지금까지 두 번 실패했고 원인은 원본 선택이다.

- char_clerk_v1: 5~6등신이라 플레이어, 차사(3~4등신)와 계열이 다르다. 미채택
- char_style_ref_clerk_red: 등신과 색은 맞지만 16개 포즈가 전부 3/4 각도다.
  정면 고정이 필요한 자리라 쓸 수 없다

## 배치 제약 (반드시 지킬 것)

창구는 hub_bg_full.png의 카운터 개구부다. 월드 좌표 기준이며 배경 y = 월드 y + 13.

| 구간 | 월드 y | 비고 |
| --- | --- | --- |
| 위 창 개구부 | 78 ~ 105 | 폭 25 (x 1185~1209) |
| 가운데 가로대 | 106 ~ 112 | 배경이 인물 앞을 가로지른다 |
| 아래 작은 창구 | 113 ~ 122 | 표를 주고받는 자리. 창구는 여기서 시작한다 |
| 카운터 선반 | 123 | 이 아래는 보이지 않는다 |

- 인물은 아래 작은 창구 바닥(월드 122)부터 위로 서고, 머리 끝이 월드 88 근처에 온다.
  위 창 상단 78~88은 알전구 자리로 비운다
- 인물 폭은 23픽셀을 넘지 않는다. 갓 챙이 창틀 기둥을 넘으면 몸이 잘려 보인다.
  챙이 넓은 갓 대신 폭이 좁은 관모(사모 또는 유건) 쪽이 안전하다
- 가로대가 가슴을 가로지르는 것은 정상이다. 창살 뒤에 선 것으로 읽혀야 한다

## 생성 설정 (S1, PixelLab)

- 도구: 캐릭터 생성 (사이드뷰 캐릭터), 정면 1방향만
- 스타일 레퍼런스: art_src/style_refs/char_style_ref_clerk_red.png (색과 등신 기준),
  art_src/style_refs/char_style_ref_saja_v3.png (선과 명암 기준)
- 프롬프트:

```
pixel art, front view facing the viewer directly, both eyes visible and symmetric,
tired old afterlife records clerk standing behind a service window,
dark red official robe with a wide sash, narrow black official cap (not a wide brim hat),
slumped shoulders, heavy eyelids, dark circles under the eyes, weary expression,
holding a ledger and a seal stamp, chest-up composition, dark muted night palette,
warm lamp light from above, 3 to 4 head-tall proportions, thick dark outline
```

- 주요 파라미터: 방향 1(정면 고정), 크기 24x40 또는 48x80 후 축소, 프레임은 아래 동작표대로
- 채택 기준: 정면 고정, 폭 23 이하, 3~4등신, 피곤한 인상이 한눈에 읽힐 것

## 동작 (피곤한 접수 관원)

느리게 움직인다. 빠른 동작은 이 캐릭터의 성격과 맞지 않는다 (사용자 지침).

| 클립 | 프레임 | 속도 | 내용 |
| --- | --- | --- | --- |
| work | 4 | 3fps | 장부를 넘기며 숨을 쉰다. 어깨가 처져 있다 |
| work_scroll | 4 | 2.4fps | 도장을 들었다 놓는다 |
| spaceout | 4 | 2fps | 고개가 천천히 떨어졌다 다시 든다. 졸음 |
| startled | 2 | 4fps | 놀라 고개를 든다. 이 클립만 조금 빠르다 |

## 후처리 (S2)

- 명령: python3 tools/pipeline/bake_clerk.py (원본 경로를 새 생성물로 바꾼 뒤 실행)
- 굽는 단계에서 인게임 크기로 축소를 끝낸다. 씬 scale은 1로 둔다

## 채택 결과

- 1차 (char_clerk_v2.zip, 48픽셀): 인물이 38x45로 나왔다. 창 폭 25에 넣으려면
  0.63배로 줄여야 하고 얼굴이 뭉갠다. 미채택. 프롬프트의 "챙 넓은 갓이 아니라"를
  모델이 무시해 갓이 그대로 나온 것도 폭이 커진 원인이다
- 2차 (char_clerk_v3.zip, 32픽셀): 인물 21x28. 창에 맞았으나 창구 배치 자체가
  폐기되어 미채택
- 3차 (char_clerk_v4.zip, 48픽셀, 전신 서 있는 자세): 인물 32x46. 창구 앞 바닥에
  차사와 같은 방식으로 세운다. 채택 (2026-08-09 배치 방침 변경)
- 교훈: 창 폭이 25면 캔버스도 32로 잡는다. 48로 뽑아 줄이는 경로는 성립하지 않는다

## 결과

- 최종 파일: assets/sprites/npc/clerk_*.png, assets/sprites/npc/clerk_frames.tres
- 함께 쓰는 것: assets/sprites/bg/hub_counter_front.png (카운터 전면 가림),
  assets/sprites/fx/bulb_glow.png (창구 안 알전구)
- 배치: 머리 끝 월드 88, 발치 116. 위 창에 얼굴, 가로대가 가슴, 아래 창구에 관복과 손
- 동작 4종은 PixelLab이 스틸만 주므로 bake_clerk.py가 픽셀 이동으로 만든다
- 메모: 원본 zip 사본은 art_src/generated/pixellab/_to_delete/에 있다 (사용자가 삭제)
