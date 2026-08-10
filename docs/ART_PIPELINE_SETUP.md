# 아트 파이프라인 셋업 가이드 (Mac)

최종 수정: 2026-07-29
대상: Mac 개발 환경 (docs/MAC_SETUP.md 완료 상태 전제)
목적: 이 문서만 보고 PixelLab 가입부터 첫 생성 테스트, 산출물 정리까지 수행한다
컨셉과 원칙: docs/ART_PIPELINE.md 참고. 이 문서는 실행 절차만 다룬다

예상 소요: 가입과 구독 15분, 첫 생성 테스트 30분, API 연결 확인(선택) 15분

## 진행 순서 요약

1. 사전 확인
2. PixelLab 가입, 구독, 이용약관 기록
3. 첫 생성 테스트 (웹 UI: 타일셋, UI 요소)
4. 후처리 스크립트 확인
5. API 연결 확인 (선택)
6. 완료 체크리스트

## 1. 사전 확인

- [ ] 저장소 최신화: `git pull`
- [ ] Python 3.10 이상: `python3 --version` (MAC_SETUP.md에서 확인 완료 상태)
- [ ] Pillow 설치: `python3 -m pip install pillow` (Homebrew Python이 externally-managed 오류를 내면 MAC_SETUP.md의 pipx/venv 대응 참고)
- [ ] Aseprite 설치 여부 확인 (S3 마감용. 없으면 aseprite.org에서 구매, 약 20달러)

로컬 GPU, 모델 다운로드, ComfyUI 설치는 필요 없다. 생성은 전부 PixelLab 클라우드에서 수행된다.

## 2. PixelLab 가입, 구독, 이용약관 기록

1. https://www.pixellab.ai 가입
2. 이용약관 확인: https://www.pixellab.ai/termsofservice 에서 상용 이용 범위와
   산출물 권리 귀속을 확인하고 이 문서 하단 기록란에 요지를 적는다 (구독 전에 수행)
3. 요금제 구독: Tier 1 (Pixel Apprentice, 월 12달러, 연속 구독 시 할인 최대 9달러).
   이미지 최대 320x320, 애니메이션 도구 포함. 스타일 탐색만 먼저 해보려면 무료
   등급(최대 200x200)으로 시작해도 된다. 구독 시작일을 기록란에 적는다
4. 해상도 한도 참고: 타일 32x32, 캐릭터 48x48 기준이면 Tier 1로 충분하다.
   400x400이 필요해지면 Tier 2 검토 (ART_PIPELINE.md 6장)

## 3. 첫 생성 테스트 (웹 UI)

M2 소비처 우선순위(UI와 타일)에 맞춰 타일셋과 UI부터 검증한다.

### 3.1 사이드스크롤러 타일셋

1. PixelLab 웹에서 타일셋(사이드스크롤러) 도구를 연다. 튜토리얼 영상이 홈페이지
   Tutorial 절에 있다 (Tileset Sidescroller)
2. 1막 밤시장 테마로 지면 타일을 생성한다. 프롬프트 예:
   `night market wooden floor, warm lantern light, korean folklore, pixel art`
3. 타일 크기 16x16과 32x32를 각각 생성해 인게임 스케일 후보를 비교한다
4. 결과를 `art_src/generated/pixellab/`에 저장 (git 제외, 로컬 보관)
5. 에셋 요청서를 작성한다: `art_src/requests/` 아래, request_template.md 복사.
   도구명, 프롬프트, 크기, 채택 여부를 기록한다

### 3.2 UI 요소

1. UI 도구(Create UI elements)를 연다
2. 체력바 또는 버튼 1종을 생성한다. 프롬프트 예:
   `health bar frame, korean traditional pattern border, dark wood, pixel art`
3. 동일하게 저장과 요청서 기록

### 3.3 품질 판단

- 타일: 이음새 연결 상태, 픽셀 밀도, 톤을 확인한다. 기준 미달이면 프롬프트와
  레퍼런스를 바꿔 3회 이상 반복해 보고, 그래도 미달이면 ART_PIPELINE.md 9장의
  대체 경로(Retro Diffusion 비교)를 연다
- 채택본이 나오면 스타일 레퍼런스 후보로 `art_src/style_refs/`에 복사한다
  (S0 스타일 정의의 시작점)

## 4. 후처리 스크립트 확인

S2 스크립트는 외부 API 출력에 대응한다 (2026-07-29 개정: 크기 유지 모드).

1. 생성물 하나로 동작 확인:

```
python3 tools/pipeline/postprocess.py art_src/generated/pixellab/생성물.png \
    --out /tmp/test_out.png --alpha-threshold 128
```

2. 크기가 유지되고 반투명 픽셀이 제거되면 정상. 팔레트 강제(`--palette`)는
   전역 팔레트 확정 후 본격 사용한다
3. 확인 후 /tmp/test_out.png는 삭제한다

## 5. API 연결 확인 (선택)

웹 UI 반복이 부담될 만큼 동종 에셋이 많아지면 API로 자동화한다. 당장은 건너뛰어도 된다.

1. API 키 발급: https://www.pixellab.ai/account
2. 키 보관: 저장소 루트의 `.env.example`을 복사해 `.env`를 만들고 키를 적는다.
   `.env`는 `.gitignore`에 등록되어 있어 커밋되지 않는다

```
PIXELLAB_SECRET=발급받은_토큰
```

3. 설치: `python3 -m pip install pixellab`
4. 연결 확인 (정확한 엔드포인트와 파라미터는 https://api.pixellab.ai/v2/docs 에서
   최신 명세를 확인한다. 아래는 연결 확인용 최소 예제):

```python
import pixellab

client = pixellab.Client.from_env_file(".env")

response = client.generate_image_pixflux(
    description="pixel art night market lantern, warm light",
    image_size={"width": 64, "height": 64},
)
response.image.pil_image().save("art_src/generated/pixellab/test_api.png")
```

5. 실행 후 `git status`로 `.env`가 추적되지 않음(ignored)을 확인한다
6. API 종량 과금은 구독과 별도다. 단가는 ART_PIPELINE.md 6장 표 참고

## 6. 완료 체크리스트

작업 종료 시 아래를 확인하고 커밋한다 (커밋은 사용자가 직접 수행).

- [ ] PixelLab 가입, 이용약관 확인 결과 기록란 기입
- [ ] 구독 시작 (등급과 시작일 기록)
- [ ] 타일셋 16/32 비교 생성, UI 1종 생성, art_src/generated/pixellab/에 저장
- [ ] 요청서 작성 (도구, 프롬프트, 옵션, 채택 여부)
- [ ] 채택본을 art_src/style_refs/에 복사 (스타일 레퍼런스 시작점)
- [ ] postprocess.py 크기 유지 모드 동작 확인
- [ ] (선택) API 키 발급 시 .env 생성, git 미추적 확인

## 트러블슈팅

| 증상 | 조치 |
|---|---|
| 타일 이음새가 어긋남 | 같은 시드/설정으로 재생성 반복. 잔여 어긋남은 Aseprite에서 수동 보정 (S3) |
| 캐릭터 방향별 실루엣이 어긋남 | 기본 포즈(정면)를 먼저 채택, 확정한 뒤 방향 생성을 실행한다. 스타일 레퍼런스 이미지를 추가한다 |
| 결과 톤이 막별 팔레트와 안 맞음 | 팔레트 강제(forced palette) 입력을 쓰거나 S2에서 --palette로 양자화한다 |
| API 키 오류 (401 등) | .env 파일 위치와 키 값 확인. 계정 페이지에서 재발급 후 교체 |
| 구독 해상도 초과 (320x320) | Tier 1 한도. Tier 2 이상 전환 검토 (ART_PIPELINE.md 6장) |
| pip 설치 시 externally-managed 오류 | MAC_SETUP.md 참고 (venv 또는 pipx 사용) |

## 기록란 (수행 후 기입)

- PixelLab 가입일: 2026-07-30
- 구독 시작일과 요금제: 2026-07-30, Tier 1 (Pixel Apprentice, 월 12달러, 월 2,000 generations, 최대 320x320)
- 등급 변경: 2026-07-30 Tier 2 (Pixel Artisan, 월 24달러, 월 5,000 generations, 최대 512x512) 전환 결정. 대형 오브젝트 대응 (DECISIONS)
- 이용약관 확인 결과 (상용 이용 범위, 산출물 권리 귀속): (미기입)
- 타일셋 첫 생성 소감 (16 대 32, 품질 판단): (미기입)
- UI 첫 생성 소감: (미기입)
- 특이사항: (미기입)

## 변경 이력

- 2026-07-29: Mac 기준 전면 재작성 (docs/DECISIONS.md 2026-07-29 항목). ComfyUI 설치, 모델 다운로드, Windows 절차 전부 제거. PixelLab 단일 경로로 재구성, 타일셋과 UI 첫 생성 테스트를 M2 우선순위에 맞춰 전면 배치
- 2026-07-27: 9장 PixelLab API 설정과 사용 신설
- 2026-07-22: 초안 작성 (Cowork)
