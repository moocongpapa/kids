# kids

모모숲 유아 콘텐츠 앱 작업 공간입니다.

- [제품 계획](PRD.md)
- [Flutter 앱과 콘텐츠](momosup/README.md)
- [Render 백엔드 안내](momosup/backend/README.md)

Render Blueprint 파일은 `momosup/render.yaml`에 있으며, Web Service의 루트 디렉터리는 `momosup`입니다.

이 로컬 작업 공간은 `main`에서 커밋하면 `.githooks/post-commit`으로 `origin/main`에 푸시하도록 설정합니다. 다른 복제본에서는 `git config core.hooksPath .githooks`를 한 번 실행해야 같은 동작을 사용합니다.
