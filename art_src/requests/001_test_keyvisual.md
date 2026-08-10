# 에셋 요청서: 001 파이프라인 스모크 테스트 (키비주얼 후보)

목적: ComfyUI 설치 검증 + M0 컨셉 탐색용 키비주얼 후보 생성. 최종 에셋이 아니다.
폐기 (2026-07-29): 로컬 ComfyUI 경로 폐기로 이 요청서는 수행하지 않는다. 컨셉 탐색은 PixelLab 경로로 대체 (docs/ART_PIPELINE.md)

## 기본 정보

- 에셋 이름: test_keyvisual
- 유형: 컨셉아트
- 최종 크기: 원본 유지 (후처리 불필요, 탐색용)
- 팔레트: 자유
- 상태: 대기

## 생성 설정 (S1)

- 워크플로: 생성 후 tools/comfyui/workflows/pixel_base_v1.json 으로 저장할 것
- 모델: Pixel Art Diffusion XL (설치 가이드 3장)
- LoRA와 강도: 없음 (체크포인트 단독) 또는 pixel-art-xl-v1.1 @ 1.0 비교
- 프롬프트 (수정해서 탐색):

```
pixel art, side view of a lone hooded adventurer standing at the entrance of
a dark ruined underground fortress, torchlight, atmospheric, detailed pixel art,
2D platformer game key visual
```

- 네거티브 프롬프트:

```
blurry, photo, realistic, 3d render, text, watermark, deformed
```

- 생성 해상도: 1024x1024
- 샘플러, 스텝, CFG: DPM++ 2M Karras, 25, 7 (모델 페이지 권장값이 있으면 우선)
- 채택 시드: (생성 후 기록)

## 검증 항목 (이 요청서의 실제 목적)

- [ ] 같은 시드로 두 번 생성했을 때 동일 출력 확인 (재현성)
- [ ] 4장 이상 생성, 마음에 드는 결과의 시드를 위에 기록
- [ ] 워크플로 JSON 내보내기 후 커밋
- [ ] 소요 시간 체감 기록 (장당 몇 초)

## 결과

- 채택 이미지: art_src/generated/ 에 보관 (git 제외, 로컬 보관)
- 메모: (소요 시간, 품질 소감, 다음 탐색 방향)
