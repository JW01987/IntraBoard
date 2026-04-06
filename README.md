# IntraBoard

사내 구성원을 위한 내부 업무 게시판 시스템입니다.
Spring Boot 기반으로 Flutter를 통해 웹과 앱을 함께 제공합니다.

<br>

## 📸 스크린샷

> 추후 추가 예정

<br>

## 🛠 기술 스택

**Backend**
- Java 17
- Spring Boot 4.x
- MyBatis
- MySQL 8.x

**Frontend (Web)**
- JSP
- Quill.js (리치 텍스트 에디터)
- Flutter 3.x
- http 패키지 (REST API 연동)

<br>

## ⚙️ 주요 기능

### 인증
- 세션 기반 로그인 / 로그아웃
- 권한(ADMIN / USER)에 따른 메뉴 및 버튼 노출 제어

### 게시판
- 게시글 CRUD
- 리치 텍스트 에디터 (글씨 크기, 볼드, 이탤릭 등)
- 파일 첨부 (이미지 포함)
- 게시글 상태 관리 (진행중 / 완료)
- 페이징 처리

### 검색 및 필터
- 제목 검색
- 게시글 상태 필터
- 기간 필터 (1주 / 1개월 / 3개월)

### 댓글
- 댓글 / 대댓글
- 권한에 따른 수정 / 삭제 제어

### Flutter 앱
- 로그인 (세션 쿠키 유지)
- 게시글 목록 조회 및 페이징
- 게시글 상세 및 댓글 조회
- Android 뒤로가기 버튼 / 제스처 처리

<br>

## 🗂 프로젝트 구조
```
```

<br>

## 🗄 ERD

```
user
├── id (PK)
├── username
├── password
├── role (ADMIN / USER)
└── created_at

post
├── id (PK)
├── user_id (FK → user)
├── title
├── content
├── status
├── created_at
└── updated_at

comment
├── id (PK)
├── post_id (FK → post)
├── user_id (FK → user)
├── parent_id (FK → comment, 대댓글)
├── content
└── created_at

file
├── id (PK)
├── post_id (FK → post)
├── original_name
├── saved_name (UUID)
├── file_path
└── created_at
```

<br>

## 🚀 실행 방법

### 사전 준비
- Java 17 이상
- MySQL 8.x
- Flutter 3.x (앱 실행 시)

### 백엔드 실행

### Flutter 앱 실행



<br>

## 🔑 테스트 계정

| 권한 | 아이디 | 비밀번호 |
|------|--------|----------|


<br>

## 📌 트러블슈팅

> 개발하면서 겪은 문제와 해결 과정을 기록합니다.

### 추후 작성 예정

<br>

## 📅 개발 기간

2026.04 ~ 2026.05 · 개인 프로젝트
