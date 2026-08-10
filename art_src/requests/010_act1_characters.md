# 에셋 요청서: act1_characters (플레이어 + 잡도깨비 첫 생성)

작성: 2026-07-30 (A1 세션)
목적: 인게임 캐릭터 첫 생성과 배경 마스터 위 스케일 테스트. 채택 시 인게임 카테고리 앵커로 승격
근거 문서: docs/ART_STYLE.md 2장 (32x32, SD 2~3등신, 검정 아웃라인), docs/GDD.md (제대군인 주인공), reference/act1_dokkaebi (도깨비 고증)

## 공통 생성 설정

- 도구: Character creator v3 (템플릿, sidescroller camera 베타). 8방향 자동 생성, 사이드뷰 사용분은 East/West
- 실행: Character 하위 시스템의 Generate in Background는 예외적으로 사용 가능 (자체 큐 안정 확인)
- 애니메이션: v3 템플릿 Running 등 제공 템플릿 우선. 방향별 개별 생성, West는 East 미러 지원

## 캐릭터 목록

| # | 캐릭터 | 스프라이트/캔버스 | 방향 | 애니메이션 | 상태 |
|---|---|---|---|---|---|
| 1 | 플레이어 (제대군인) | 32급/56x56 | 8 | Running 8프레임 (South, East 완료. West는 미러) | 생성 완료, Export 다운로드 |
| 2 | 잡도깨비 v2 | 32/60x60 | 8 | 없음 (테스트 후 추가) | 생성 완료, Export 다운로드 |
| - | 잡도깨비 v1 (백업) | 48/88x88 | 8 | 없음 | 보관 (크기 오설정. 대형 변형 소재로 재활용 후보) |

## 프롬프트 기록

플레이어 (id a01565f7-60b1-49b4-a303-7cc5019d81fc):

```
modern korean young man, discharged soldier, olive green field jacket over dark shirt,
jeans and boots, short shaggy black hair, holding a rifle with a bayonet,
chibi 2.5 head proportions, small pixel art character, black outline,
muted subdued colors, determined face
```

잡도깨비 v2 (id 28c24a9a-6263-4680-9621-5e91ac909b8f):

```
small human-shaped korean dokkaebi spirit, shaggy messy dark hair,
ragged short korean hanbok in dark bluish-purple night tones,
skin tinted dusky indigo-violet, small glowing warm orange eyes,
dim-witted mischievous face, holding an old wooden pestle like a club raised over shoulder,
chibi proportions, small pixel art character, black outline, muted subdued colors,
NO horns, NO oni, NO goblin
```

## 판정 기준

- [ ] 스케일: 배경 마스터(act1_bg_master) 위 합성 시 가판대(38px), 귀문(42px) 대비 자연스러운가
- [ ] 고증: 잡도깨비에 뿔/오니/고블린 요소 없음, 더벅머리, 남보라 몸 + 난색 눈
- [ ] 아웃라인: 검정 아웃라인 유지 (인게임 요소 규칙, 배경과 구분)
- [ ] 실루엣: 야간 배경 침전 위에서 가독성 확보
- 종합 판정: (합성 테스트 후 기입)

## 결과

- 2026-07-30 두 캐릭터 생성과 Export 다운로드 완료. art_src/generated/pixellab/ 이동 완료
  - Export 구조: char_player/ (Idle 8방향 + Running east/south 각 8프레임 개별 PNG + metadata.json), char_dokkaebi/ (Idle 8방향 + metadata.json)
  - 트림 실측: 플레이어 13x28 (56x56 캔버스), 잡도깨비 19x30 (60x60 캔버스). 둘 다 32px 규격 내
- 교훈: 캐릭터 크기 입력은 클릭만으로 반영되지 않는 경우가 있어 JS로 표시값("32 × 32") 확인 후 Generate (v1 48px 오설정 사례)
- 합성 스케일 테스트 완료 (act1_char_scale_test_1x/4x.png, closeup_8x):
  - 배경 마스터 위 지면선 y=138 기준 배치. 가판대(38px), 귀문(42px) 대비 스케일 자연스러움
  - 검정 아웃라인이 야간 배경에서 실루엣 분리 확보. 고증 통과 (뿔 없음, 더벅머리, 남보라 몸 + 난색 눈, 절굿공이)
  - 관찰: 잡도깨비(30px)가 플레이어(28px)보다 2px 큼. 잡몹 위계상 축소 여부는 사용자 판정. 플레이어 소총이 East 뷰에서 어둡게 묻힘 (인게임 라이팅에서 재확인)
- 인게임 카테고리 앵커 승격 여부: (사용자 판정 후 기입)

## 1차 기각과 재설계 (2026-08-01)

- 사용자 판정: 기각. "캐릭터들이 개성이 너무 없어"
  - 플레이어: 제대군인은 총기 사용의 정당성일 뿐, 군인 캐릭터를 그리라는 의도가 아님. 군인 룩 폐기
  - 잡도깨비: 사람에서 피부색만 바꾼 수준. 문헌(reference/act1_dokkaebi) 기반 재설계 지시
- 재설계 방향:
  - 잡도깨비 v3: 외다리(독각귀) 포함 확정 (사용자 승인. 콩콩 뛰는 이동까지 확장). 도구 반변신(하반신 절굿공이), 갈기 더벅머리, 부릅뜬 눈 + 벌린 입(문양전 귀형 도상), 패랭이
  - 플레이어: 후보 3안 생성 후 사용자 선택
    - A 밤길 평상복 (회색 후드집업 + 청바지): id 0f0bbe66-9f01-42b1-b802-a75b6d301286, 60x60
    - B 현대복 + 저승 표식 (부적 + 삼베 띠): id 3c147c9a-740d-412b-a225-7767b72d3f54, 56x56
    - C 백의 시그니처 (아이보리 패딩): id 4b34fc62-3b7b-486c-a7e2-8230b39ccf4c, 60x60
  - 잡도깨비 v3: id 259b083d-930d-4f1e-91c8-171167a468e7, 60x60
- 2026-08-01 4종 생성과 Export 다운로드 완료 (각 32px 스프라이트, Sidescroller, v3)
- 합성 비교와 판정: 기각. 사용자 지시로 절차 변경 — 안을 글로 서술해 합의한 뒤 생성 (이미지 후보 선제 생성 금지, DECISIONS 2026-08-01)

## 확정 컨셉과 생성 (2026-08-01, 사용자 승인)

- 플레이어 "퇴근길의 남자" (안 1 채택): 소매 걷은 흰 셔츠 + 느슨한 넥타이 + 어두운 슬랙스 + 구두. 소총은 어깨끈으로 어설프게 멘다. 넥타이가 시그니처 (달리기 시 나부낌 예정)
  - id 87854bf1-2aef-4d6c-bbad-f9aec9a9269f, 32px/60x60, Export 완료
- 잡도깨비 "절굿공이 외다리" (문헌 기반 단일안 승인): 하반신이 낡은 절굿공이 하나(독각귀), 갈기 더벅머리, 부릅뜬 난색 눈 + 히죽 벌린 입, 패랭이, 남보라 피부
  - id ebd0f056-975c-4661-9aa9-1c922b2ebed8, 32px/60x60, Export 완료
  - 크기 위계: 캔버스 26px 설정이 UI 제약(슬라이더 키보드 미반응)으로 불가. 32로 생성 후 에셋화 단계 S2 다운스케일로 플레이어보다 작게 굳힌다
- 합성 스케일 테스트: (파일 이동 후 수행)

## 확대 재생성 (2026-08-03, 사용자 지시: 크기와 등신비 상향)

- 플레이어 v3: 48px 스프라이트 / 92x92 캔버스, "3 head proportions with longer legs" 추가. id 06d81a93-88be-43a4-9a89-693667874155. Export 완료
- 잡도깨비 v4: 40px 스프라이트 / 76x76 캔버스 (슬라이더 트랙 클릭으로 40 설정 성공. 좌표 환산 클릭이 유효했음). id a3fdc4e0-2a65-41d0-9cfe-ac54496b313b. Export 완료
- 위계: 플레이어 약 44~46px 대 잡도깨비 약 36~38px 예상 (트림 후 실측 예정)
- 주의: 확대에 따라 충돌 박스(플레이어 10x22, 적 16x24)와 스케일 규약 문구의 기준(28px) 재검토 필요
