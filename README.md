# IntraBoard

사내 구성원을 위한 B2B 내부 업무 게시판 시스템입니다.  
Spring Boot 백엔드와 Flutter 프론트엔드로 구성된 풀스택 개인 프로젝트입니다.

<br>

## 목적

사내 업무 도구로 Notion을 사용했지만 두 가지 문제가 있었습니다.

- Notion에 익숙하지 않은 구성원이 많아 실제로 활용되지 못하는 경우가 많았습니다.
- 업무 특성에 맞는 커스터마이징(게시글 상태 관리, 담당자 지정, 첨부파일 등)이 어려웠습니다.

이 문제를 해결하기 위해 누구나 쉽게 쓸 수 있고, 커스터마이징 가능한 사내 게시판을 직접 만들었습니다.

<br>
## 스크린 샷

### 로그인
#### 모바일
> <img width="378" height="666" alt="Image" src="https://github.com/user-attachments/assets/69936f64-8394-4ead-9316-86cf16d451e7" />
#### 데스크탑
> <img width="1068" height="703" alt="Image" src="https://github.com/user-attachments/assets/f6dd4e07-d333-4f39-abef-c40861c7318b" />
### 대시보드 (홈화면)
#### 모바일
> <img width="372" height="666" alt="Image" src="https://github.com/user-attachments/assets/8d409520-81c5-48ae-87f6-e345c7d710f2" />
> <img width="372" height="666" alt="Image" src="https://github.com/user-attachments/assets/dfeb4479-6d04-4dad-83e2-6ca1fac7f630" />
#### 데스크탑
> <img width="1343" height="702" alt="Image" src="https://github.com/user-attachments/assets/8c20bd7e-59d5-4c08-8eac-ad24ececc280" />

### 공지사항 게시판
#### 모바일
> <img width="372" height="666" alt="Image" src="https://github.com/user-attachments/assets/3d431b32-b8ca-45f1-b85e-bebc90de20d9" />
#### 데스크탑
> <img width="1088" height="753" alt="Image" src="https://github.com/user-attachments/assets/f7761040-d9f9-48eb-963b-9785d3447f94" />

### 이슈 게시판
#### 데스크탑
> <img width="1088" height="753" alt="Image" src="https://github.com/user-attachments/assets/c2ffb553-9293-4729-949a-ff8210bcc5ee" />
> <img width="1088" height="753" alt="Image" src="https://github.com/user-attachments/assets/f1433a4d-7aa7-48bc-a99b-a5911d50090a" />
> <img width="1088" height="753" alt="Image" src="https://github.com/user-attachments/assets/863445ce-d414-42a9-8d37-f93418318e2d" />
### 관리 화면
#### 데스크탑
> <img width="1088" height="753" alt="Image" src="https://github.com/user-attachments/assets/aa41c3e1-a380-40e4-a2ef-87ee569aa09a" />
> <img width="1088" height="753" alt="Image" src="https://github.com/user-attachments/assets/49fb6431-e7c6-4391-b0e9-fb42cfe864a8" />


<br>

## 기술 스택

| 분류 | 기술 |
|------|------|
| Language | Java 21 |
| Framework | Spring Boot 3.2.5 |
| ORM | MyBatis 3.0.3 |
| DB | MySQL 8.x |
| Frontend | Flutter 3.x |
| 인증 | 세션 기반 (HttpSession + HandlerInterceptor) |
| API 문서 | Swagger (springdoc-openapi 2.5.0) |
| 기타 | Lombok, Gradle |

<br>

## 주요 기능

### 인증 / 권한
- 세션 기반 로그인 / 로그아웃
- 회원가입 후 관리자 승인 필요 (대기 → 승인 / 거절)
- 역할 기반 접근 제어 (관리자 / 일반회원)
- 본사 직원 전용 기능 분리 (담당자 지정 등)

### 이슈 게시판 (ISSUE)
- 게시글 CRUD (작성자 / 관리자 / 담당자 수정 가능)
- 카테고리 분류: 버그/오류, 기능문의, 계정/권한, 기타
- 진행 상태 관리: 진행중 / 완료 / 미해결 / 숨김
- 중요도 설정: 낮음 / 보통 / 높음 / 긴급
- 담당자 지정 (본사 직원 전용)
- 고객사별 이슈 필터링
- 소프트 딜리트 (is_deleted 플래그)

### 공지사항 (NOTICE)
- 관리자 전용 작성 / 수정 / 삭제
- 조회수 집계

### 자료실 (ARCHIVE)
- 파일 첨부 게시글 관리

### 검색 및 필터
- 제목 키워드 검색
- 게시글 상태 / 카테고리 / 중요도 필터
- 작성자명 검색
- 기간 필터 (시작일 ~ 종료일)
- 고객사별 필터
- 내게 할당된 이슈 필터
- 페이징 처리

### 댓글
- 댓글 / 대댓글 (parent_id 기반)
- 작성자 또는 관리자만 삭제 가능

### 파일 첨부
- 다중 파일 업로드 (최대 50MB)
- UUID 기반 파일명으로 저장 (원본명 별도 보관)
- 다운로드 / 인라인 미리보기 분리

### 관리자 대시보드
- 전체 이슈 수 / 진행중 / 완료 / 긴급 현황
- 상태별 / 중요도별 / 카테고리별 통계
- 담당자별 할당 이슈 최신 5건

### 회사 / 조직 관리
- 본사 / 고객사 / 협력사 구분
- 관리자의 회사 등록 / 수정 / 삭제
- 소속 직원이 있는 회사는 삭제 불가 (외래키 제약)

<br>

## 프로젝트 구조

```
board/
├── backend/                        # Spring Boot 백엔드
│   └── src/main/java/com/company/board/
│       ├── config/
│       │   ├── WebConfig.java          # CORS, 인터셉터, 정적 리소스 설정
│       │   ├── LoginCheckInterceptor.java  # 세션 인증 인터셉터
│       │   └── SwaggerConfig.java
│       ├── controller/
│       │   ├── UserController.java     # 로그인, 회원가입, 로그아웃
│       │   ├── PostController.java     # 게시글 CRUD
│       │   ├── CommentController.java  # 댓글 CRUD
│       │   ├── NoticeController.java   # 공지사항
│       │   ├── FileController.java     # 파일 업로드/다운로드
│       │   ├── AdminController.java    # 대시보드 통계
│       │   ├── AdminUserController.java  # 회원 승인/관리
│       │   └── SystemController.java   # 카테고리, 회사 관리
│       ├── service/
│       ├── mapper/                 # MyBatis 인터페이스
│       ├── domain/                 # 도메인 모델 (Post, User, Comment 등)
│       ├── constant/               # Enum (UserRole, PostStatus, Priority 등)
│       ├── common/
│       │   └── ApiResponse.java    # 공통 응답 래퍼
│       └── util/
│           └── PasswordUtils.java  # 비밀번호 해싱
│   └── src/main/resources/
│       ├── mapper/                 # MyBatis XML 쿼리
│       ├── schema.sql              # DDL
│       ├── data.sql                # 초기 데이터
│       └── application.yml
├── frontend/                       # Flutter 프론트엔드
│   └── lib/
├── schema.sql                      # 전체 DB 스키마
└── dummy_data.sql                  # 테스트용 더미 데이터
```

<br>

## ERD

```
company
├── company_id (PK)
├── company_name
└── company_type  -- 1:본사, 2:고객사, 3:협력사

user
├── user_id (PK)
├── login_id (UNIQUE)
├── password
├── name
├── company_id (FK → company)
├── role        -- 1:관리자, 2:일반회원
└── status      -- 0:승인대기, 1:활성, 2:거절

post_status
├── status_id (PK)
└── status_name  -- 진행중, 완료, 미해결, 숨김

post_category
├── category_id (PK)
└── category_name  -- 버그/오류, 기능문의, 계정/권한, 기타

post
├── post_id (PK)
├── board_type      -- NOTICE, ISSUE, ARCHIVE
├── user_id (FK → user)
├── status_id (FK → post_status)
├── category_id (FK → post_category)
├── priority        -- 1:낮음, 2:보통, 3:높음, 4:긴급
├── assigned_user_id (FK → user)
├── title
├── content
├── view_count
├── is_deleted      -- 소프트 딜리트
└── created_at / updated_at

comment
├── comment_id (PK)
├── post_id (FK → post)
├── user_id (FK → user)
├── parent_id (FK → comment)  -- 대댓글
├── content
└── is_deleted

file
├── file_id (PK)
├── post_id (FK → post)
├── original_name
├── saved_name  -- UUID 기반
├── file_path
└── file_size
```

<br>

## API 목록

### 인증 (`/api/users`)
| Method | URL | 설명 | 인증 |
|--------|-----|------|------|
| POST | `/api/users/register` | 회원가입 | 불필요 |
| POST | `/api/users/login` | 로그인 | 불필요 |
| POST | `/api/users/logout` | 로그아웃 | 필요 |
| PUT | `/api/users/{id}/role` | 권한 변경 | 관리자 |
| GET | `/api/users/staff` | 담당자 후보 목록 | 필요 |

### 게시글 (`/api/posts`)
| Method | URL | 설명 | 인증 |
|--------|-----|------|------|
| GET | `/api/posts` | 목록 조회 (검색+페이징) | 필요 |
| GET | `/api/posts/{id}` | 상세 조회 (조회수 증가) | 필요 |
| POST | `/api/posts` | 게시글 작성 | 필요 |
| PUT | `/api/posts/{id}` | 게시글 수정 | 작성자/관리자/담당자 |
| DELETE | `/api/posts/{id}` | 게시글 삭제 (소프트) | 작성자/관리자 |
| PATCH | `/api/posts/{id}/assignee` | 담당자 지정 | 본사 직원 |

### 댓글 (`/api/comments`)
| Method | URL | 설명 | 인증 |
|--------|-----|------|------|
| GET | `/api/comments/post/{postId}` | 댓글 목록 | 필요 |
| POST | `/api/comments` | 댓글 작성 | 필요 |
| DELETE | `/api/comments/{id}` | 댓글 삭제 | 작성자/관리자 |

### 공지사항 (`/api/notices`)
| Method | URL | 설명 | 인증 |
|--------|-----|------|------|
| GET | `/api/notices` | 목록 조회 | 필요 |
| GET | `/api/notices/{id}` | 상세 조회 | 필요 |
| POST | `/api/notices` | 공지 작성 | 관리자 |
| PUT | `/api/notices/{id}` | 공지 수정 | 관리자 |
| DELETE | `/api/notices/{id}` | 공지 삭제 | 관리자 |

### 파일 (`/api/files`)
| Method | URL | 설명 | 인증 |
|--------|-----|------|------|
| POST | `/api/files/upload` | 파일 업로드 | 필요 |
| GET | `/api/files/download/{savedName}` | 파일 다운로드 | 필요 |
| GET | `/api/files/display/{savedName}` | 파일 인라인 미리보기 | 불필요 |

### 관리자 (`/api/admin`)
| Method | URL | 설명 | 인증 |
|--------|-----|------|------|
| GET | `/api/admin/dashboard` | 대시보드 통계 | 필요 |
| GET | `/api/admin/users/pending` | 승인 대기 목록 | 관리자 |
| GET | `/api/admin/users/all` | 전체 회원 목록 | 관리자 |
| PUT | `/api/admin/users/{id}/approve` | 가입 승인 | 관리자 |
| PUT | `/api/admin/users/{id}/reject` | 가입 거절 | 관리자 |
| PUT | `/api/admin/users/{id}` | 회원 정보 수정 | 관리자 |
| DELETE | `/api/admin/users/{id}` | 회원 삭제 | 관리자 |

### 시스템 (`/api/system`)
| Method | URL | 설명 | 인증 |
|--------|-----|------|------|
| GET | `/api/system/categories` | 카테고리 목록 | 필요 |
| GET | `/api/system/companies` | 회사 목록 | 불필요 |
| POST | `/api/system/companies` | 회사 등록 | 관리자 |
| PUT | `/api/system/companies/{id}` | 회사 수정 | 관리자 |
| DELETE | `/api/system/companies/{id}` | 회사 삭제 | 관리자 |

<br>

## 실행 방법

### 사전 준비

- Java 21 이상
- MySQL 8.x
- Flutter 3.x (프론트엔드 실행 시)

### 1. 데이터베이스 설정

```bash
mysql -u root -p < schema.sql
mysql -u root -p board_db < dummy_data.sql  # 테스트 더미 데이터 (선택)
```

### 2. 백엔드 설정

`backend/src/main/resources/application.yml.example`을 복사해 `application.yml`을 생성하고 DB 정보를 입력합니다.

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/board_db?serverTimezone=Asia/Seoul&characterEncoding=UTF-8
    username: root
    password: 본인_비밀번호
```

### 3. 백엔드 실행

```bash
cd backend
./gradlew bootRun
```

서버 기동 후 Swagger UI: `http://localhost:8080/swagger-ui/index.html`

### 4. Flutter 프론트엔드 실행

```bash
cd frontend
flutter pub get
flutter run -d chrome  # 웹 실행
```

<br>

## 테스트 계정

더미 데이터(`dummy_data.sql`) 삽입 후 사용 가능합니다.

| 역할 | 아이디 | 비밀번호 | 소속 |
|------|--------|----------|------|
| 관리자 | admin | admin1234 | 본사 |
| 본사 직원 | staff01 | admin1234 | 본사 |
| 고객사 직원 | client01 | admin1234 | 고객사 |

<br>

## 개발 기간

2026.04 ~ 2026.05 · 개인 프로젝트
