# PixelLab 받은편함

PixelLab에서 다운로드한 파일을 그대로 여기에 넣는다. 개명도 분류도 하지 않는다.

## 흐름

1. 사용자: PixelLab 다운로드를 이 폴더에 넣는다
2. Cowork: 정체를 확인하고 규칙 이름으로 개명해 목적지로 옮긴다
   - 생성 에셋: art_src/generated/pixellab/ 아래 분류 폴더
   - 스타일 기준 레퍼런스: art_src/style_refs/
   - 도식과 비교 이미지: art_src/references/
3. Cowork: S2 후처리와 인게임 반영(assets/sprites/ 배치, 씬 연결)까지 진행한다
4. Cowork: 결과를 요청서 채택 결과란과 docs/PROGRESS.md에 기록한다

정리가 끝나면 이 폴더는 비워진다. 남아 있는 파일은 아직 처리되지 않은 것이다.
폴더 자체는 지우지 않는다. 지우면 다음 반입 때 다시 만들어야 한다.

## 규칙

- 이 폴더의 내용물은 커밋하지 않는다 (.gitignore). .gdignore로 Godot 임포트도 막는다
- 정체가 불명확한 파일은 Cowork가 사용자에게 묻고, 답이 오기 전에는 옮기지 않는다
- 기존 채택본과 내용이 같은 재다운로드는 art_src/generated/pixellab/archive/로 보낸다
- Cowork는 파일을 삭제할 수 없다 (실행 환경 제약). 삭제 대상은 art_src/generated/pixellab/_to_delete/로 모으고 사용자가 폴더째 지운다
