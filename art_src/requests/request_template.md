# 에셋 요청서: (에셋 이름)

이 파일을 복사해 새 요청서를 만든다. 파일명: 순번_이름.md (예: 005_ui_health_bar.md)

## 기본 정보

- 에셋 이름: (예: ui_health_bar)
- 유형: 컨셉아트 | UI | 타일셋 | 배경 | 오브젝트 | 캐릭터 | 적
- 최종 크기: (예: 32x32)
- 팔레트: (예: art_src/palettes/global.gpl, 미정이면 "자유")
- 상태: 대기 | 생성 중 | 마감 중 | 임포트 완료

## 생성 설정 (S1, PixelLab)

- 도구: (웹 도구명 또는 API 엔드포인트. 예: 사이드스크롤러 타일셋 / create-tileset-sidescroller)
- 스타일 레퍼런스: (예: art_src/style_refs/tile_market_ref.png, 없으면 "없음")
- 저장된 캐릭터/오브젝트 ID: (캐릭터, 오브젝트 유형만. 재사용 근거)
- 프롬프트:

```
(프롬프트)
```

- 주요 파라미터: (크기, 방향 수, 프레임 수, 팔레트 강제 여부 등)
- 채택 결과: (생성 후 기록. 반복 횟수와 채택 기준 메모)

## 후처리 (S2)

- 명령: (예: python3 tools/pipeline/postprocess.py in.png --out out.png --palette art_src/palettes/global.gpl --alpha-threshold 128)

## 결과

- 최종 파일: (예: assets/sprites/ui/health_bar.png)
- 메모: (수작업 보정 내용, 특이사항)
