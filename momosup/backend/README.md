# Render 스테이징 콘텐츠 안전 API

2026-09-29 확인: [`momosup-safety-api-staging`](https://momosup-safety-api-staging.onrender.com/health)와 전용 PostgreSQL이 Render 싱가포르 지역에 배포되어 있다. `/health`는 DB 연결을 확인하고 정상 응답한다. 현재 Flutter 앱은 이 API를 호출하지 않는다. 실제 아이·보호자 계정, 결제, 데이터 동기화 기능은 없고 데이터베이스에는 차단한 콘텐츠 ID와 사유만 저장한다.

## 기능

- `GET /health`: Postgres 연결 확인
- `GET /v1/catalog`: 사람 검수·권리 확인·필수 음성 작업의 승인 메타데이터가 기록된 콘텐츠 중 차단되지 않은 ID 목록만 반환
- `POST /v1/admin/content/:id/disable`: 관리자 토큰으로 차단 사유를 기록하고 연결된 기기의 다음 목록 요청에서 숨김

목록의 `digest`는 변경 감지용 SHA-256 해시이지 서버 서명이나 위조 방지 인증이 아니다. 현재 Flutter 앱에 다운로드 팩·온라인 재확인·오프라인 24시간 만료가 없으므로 **원격 즉시 차단을 보장하지 않는다**. 공개 MVP 전에는 인증된 목록, 앱 측 fail-closed 정책, 오프라인 만료·실기기 테스트, 운영자 감사 로그와 관리자 2단계 인증이 필요하다.

## 로컬 검사

```sh
npm ci
npm test
```

실제 DB에서 실행하려면 `schema.sql`을 **별도 테스트용 Postgres**에 적용한다. `DATABASE_URL`과 길이 32자 이상의 `ADMIN_TOKEN`을 로컬 비밀 환경 변수로 제공하고 `npm start`한다. 토큰이나 DB URL을 코드, 문서, 채팅, Git에 넣지 않는다. 앱의 안전 상태를 이 API에 의존시키기 전에는 서버 장애 시 놀이를 안전하게 막는 시험이 필요하다.

스테이징 Web Service는 `0.5c-512mb`, PostgreSQL은 `0.1c-256mb`·1GB다. DB 외부 접속은 차단되어 있고 복구 화면에는 최근 3일 시점 복원이 제공된다. 실제 아동 데이터는 이 서비스에 보내지 않는다. `DATABASE_URL`과 `ADMIN_TOKEN`은 Render 비밀 환경 변수로 관리한다. [Render 환경 변수](https://render.com/docs/configure-environment-variables), [Render PostgreSQL](https://render.com/docs/postgresql).

## 초기 배포 기록과 운영

`../render.yaml`로 스테이징 Web Service와 전용 Postgres를 생성했다. 코드 푸시 후 API를 갱신하려면 Render에서 **Manual Deploy**를 실행한다. `autoDeployTrigger: off`이므로 Git 푸시만으로 API가 갱신되지 않는다. 월 비용은 Render [가격표](https://render.com/pricing)와 대시보드 청구 내역에서 확인한다.

두 새 리소스는 Blueprint에는 연결되어 있으나 기존 `Wan's Toys / kids edu` 환경에는 아직 배정되지 않았다. 해당 환경은 비어 있다. 다른 운영 서비스와 데이터베이스를 공유하지 않는다.

아래는 첫 배포 절차의 기록이다. 이미 만들어진 스테이징 리소스를 중복 생성하지 않는다.

1. [Render 대시보드](https://dashboard.render.com/)에서 기존 계정에 로그인한다. `Billing`에서 결제수단과 실제 청구·알림 기능을 확인한다. 지출 알림은 하드 결제 한도를 의미하지 않으므로 주 1회 청구액을 확인한다. 기존 `kids edu` 환경을 별도 스테이징 위치로 사용할지 결정한다. `momosup-safety-api-staging` 및 `momosup-content-db-staging`이라는 이름의 기존 리소스가 **없는지 먼저 확인**한다. 동일 이름이 있으면 Blueprint가 그 리소스를 바꾸려 할 수 있으므로 이름을 변경한다.
2. `kids/`를 Git 저장소의 루트로 푸시한다. 앱과 백엔드는 그 안의 `momosup/`에 있다. 키·토큰·실제 아동 정보는 커밋하지 않는다. Render에서 Git 제공자와 이 저장소만 연결한다. Web Service의 `rootDir: momosup`이 빌드·실행 명령의 기준 경로다.
3. `New > Blueprint`를 열고 해당 저장소를 연결한다. Blueprint 파일 경로는 **`momosup/render.yaml`**이다. 미리보기에서 **신규 Web Service 1개와 신규 Postgres 1개만** 나타나는지, 싱가포르 지역·유료 플랜·DB 디스크 1GB·월 예상액을 확인한 다음에만 `Deploy Blueprint`를 누른다. 현재 YAML의 `services`와 `databases`는 최상위에 있어 새 리소스를 기존 `kids edu` 환경에 자동 배정하지 않는다. **이 작업은 유료 리소스를 생성하므로 자동으로 실행하지 않았다.** [Render Blueprint 설정](https://render.com/docs/infrastructure-as-code), [YAML의 프로젝트 배정 규칙](https://render.com/docs/blueprint-spec)
4. 배포가 끝나면 Render 서비스 목록에서 **새 Web Service와 새 Postgres 두 개만** 선택하고 `Move`로 기존 `Wan's Toys` 프로젝트의 `kids edu` 환경에 넣는다. 이 단계에서 다른 서비스는 선택하지 않는다. Render의 프로젝트 환경에 별도 네트워크 격리 설정이 있다면 두 리소스 사이 연결을 다시 확인한다. [프로젝트와 환경](https://render.com/docs/projects)
5. Blueprint가 `DATABASE_URL`을 새 DB의 **내부 접속 URL**로 연결하고 `ADMIN_TOKEN`을 생성한다. 토큰을 채팅·Git·앱에 넣지 않는다. DB는 `ipAllowList: []`로 외부 접속을 막으며 Web Service 내부에서만 접속한다. 배포 전 단계의 `npm run migrate`가 `content_blocks` 테이블을 만든다. Web Service의 `autoDeployTrigger: off`는 코드 푸시의 자동 배포만 끈다. `render.yaml` 변경에 따른 Blueprint 자동 동기화도 원치 않으면 Blueprint의 `Settings > Auto Sync`를 `No`로 설정한다. [환경 변수](https://render.com/docs/blueprint-spec), [Blueprint 자동 동기화](https://render.com/docs/infrastructure-as-code)
6. Web Service의 공개 URL에서 `/health`가 `{"ok":true}`인지 확인한다. `/v1/catalog`은 마지막 수동 배포 커밋의 승인 목록을 반환하므로, 배포 후 의도한 콘텐츠 ID와 차단 목록을 비교한다. 서비스 로그에 키나 DB URL이 노출되지 않는지도 본다.
7. Dashboard의 Postgres `Recovery`에서 유료 DB의 복구 기능을 확인하고 테스트 복구 계획을 세운다. Hobby의 PITR 창은 공식 안내상 3일이다. 이 DB에는 현재 차단 ID만 넣고, 아동 프로필·그림·음성·생년월일은 보내지 않는다. [Render 백업](https://render.com/docs/postgresql-backups)

`autoDeployTrigger: off`이므로 이후 코드 푸시가 즉시 Web Service에 배포되지는 않는다. Blueprint YAML 변경은 별도 자동 동기화 설정의 영향을 받는다. 승인 콘텐츠 배포 시에도 운영자가 변경·검수·수동 배포를 분리할 수 있게 하기 위한 설정이다. 이 API는 **공개 출시용 인증·서명·다기기 동기화·즉시 차단 시스템이 아니다**. 현재는 유료 인프라와 안전 목록 동작을 연습하는 스테이징이다. 한국 사용자의 개인정보를 Render 싱가포르 지역에 저장하기 전에는 국외 이전·수탁·보존·삭제 절차에 대한 별도 검토가 필요하다.
