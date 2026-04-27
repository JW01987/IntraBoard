-- IntraBoard Dummy Data SQL
-- Created at: 2026-04-27
-- Description: 초기 데이터 초기화 및 대량의 더미 데이터 삽입 (본사, 고객사, 협력사, 유저, 게시글, 댓글, FAQ)

SET FOREIGN_KEY_CHECKS = 0;

-- 기존 데이터 초기화 (기존 데이터는 초기화 필요 조건 충족)
TRUNCATE TABLE `comment`;
TRUNCATE TABLE `file`;
TRUNCATE TABLE `post`;
TRUNCATE TABLE `user`;
TRUNCATE TABLE `company`;
TRUNCATE TABLE `post_status`;
TRUNCATE TABLE `post_category`;
TRUNCATE TABLE `faq`;

SET FOREIGN_KEY_CHECKS = 1;

-- 1. 회사 데이터 (본사 1, 고객사 3, 협력사 2, 어드민 1)
INSERT INTO `company` (`company_id`, `company_name`, `company_type`) VALUES
(1, '(주)인트라보드', 1), -- 본사
(2, '(주)에이치솔루션', 2), -- 고객사
(3, '(주)미래소프트', 2),
(4, '(주)케이텍', 2),
(5, '(주)파트너스', 3), -- 협력사
(6, '(주)네트웍스', 3)
ON DUPLICATE KEY UPDATE company_name=VALUES(company_name), company_type=VALUES(company_type);

-- 2. 유저 데이터 (회사별 2~3명, 본사 관리자 포함)
-- 비밀번호: admin1234 (SHA-256: ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270)
-- status: 1 (활성), role: 1 (슈퍼관리자), 2 (일반회원)
INSERT INTO `user` (`user_id`, `login_id`, `password`, `name`, `company_id`, `role`, `status`) VALUES
(1, 'admin', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '최관리', 1, 1, 1),
(2, 'staff01', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '김본사', 1, 2, 1),
(3, 'staff02', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '이운영', 1, 2, 1),
(4, 'sys_admin', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '시스템관리자', 1, 1, 1),
(5, 'sys_staff', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '권운영', 1, 2, 1),
(6, 'h_user1', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '박에이치', 2, 2, 1),
(7, 'h_user2', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '정솔루션', 2, 2, 1),
(8, 'm_user1', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '강미래', 3, 2, 1),
(9, 'm_user2', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '윤소프트', 3, 2, 1),
(10, 'k_user1', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '최케이', 4, 2, 1),
(11, 'k_user2', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '조텍', 4, 2, 1),
(12, 'p_user1', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '한파트너', 5, 2, 1),
(13, 'p_user2', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '임협력', 5, 2, 1),
(14, 'n_user1', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '오네트', 6, 2, 1),
(15, 'n_user2', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '서웍스', 6, 2, 1),
-- 승인 대기 유저 (status = 0)
(16, 'pending01', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '대기자1', 2, 2, 0),
(17, 'pending02', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '대기자2', 3, 2, 0),
(18, 'pending03', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '대기자3', 5, 2, 0),
(19, 'pending04', 'ac9689e2272427085e35b9d3e3e8bed88cb3434828b43b86fc0596cad4c6e270', '대기자4', 1, 2, 0)
ON DUPLICATE KEY UPDATE name=VALUES(name), company_id=VALUES(company_id), role=VALUES(role), status=VALUES(status);

-- 3. 게시글 상태 및 카테고리 (이미 있음 조건, 보장용)
INSERT INTO `post_status` (`status_id`, `status_name`) VALUES
(1, '진행중'), (2, '완료'), (3, '미해결'), (4, '숨김')
ON DUPLICATE KEY UPDATE status_name=VALUES(status_name);

INSERT INTO `post_category` (`category_id`, `category_name`) VALUES
(1, '버그/오류'), (2, '기능문의'), (3, '계정/권한'), (4, '기타')
ON DUPLICATE KEY UPDATE category_name=VALUES(category_name);

-- 4. 게시글 (NOTICE): 5개
INSERT INTO `post` (`post_id`, `board_type`, `user_id`, `title`, `content`, `created_at`) VALUES
(1, 'NOTICE', 1, '[공지] IntraBoard 서비스 점검 안내 (5월 10일)', '안녕하세요. 관리자입니다. 시스템 안정화를 위한 정기 점검이 예정되어 있습니다.\n\n- 일시: 2026년 5월 10일 02:00 ~ 06:00\n- 영향: 서비스 접속 불가', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(2, 'NOTICE', 1, '[안내] 새로운 이슈 트래킹 기능 업데이트', '이슈 트래킹 기능이 더욱 강력해졌습니다. 이제 담당자를 지정하고 우선순위를 한눈에 확인하세요.', DATE_SUB(NOW(), INTERVAL 15 DAY)),
(3, 'NOTICE', 1, '[공지] 보안 강화를 위한 비밀번호 변경 캠페인', '회원 여러분의 소중한 정보를 위해 주기적인 비밀번호 변경을 권장합니다.', DATE_SUB(NOW(), INTERVAL 30 DAY)),
(4, 'NOTICE', 1, '[필독] 자료실 이용 가이드 안내', '자료실 업로드 시 파일 용량 제한(100MB)을 준수해 주시기 바랍니다.', DATE_SUB(NOW(), INTERVAL 45 DAY)),
(5, 'NOTICE', 1, '[공지] 상반기 고객사 만족도 조사 실시', '더 나은 서비스를 위해 설문에 참여해 주세요. 추첨을 통해 선물을 드립니다.', DATE_SUB(NOW(), INTERVAL 60 DAY))
ON DUPLICATE KEY UPDATE title=VALUES(title), content=VALUES(content);

-- 5. 게시글 (ISSUE): 20개 (다양한 category, priority, status, assigned_user)
-- priority: 1:낮음, 2:보통, 3:높음, 4:긴급
-- status_id: 1:진행중, 2:완료, 3:미해결, 4:숨김
INSERT INTO `post` (`post_id`, `board_type`, `user_id`, `status_id`, `category_id`, `priority`, `assigned_user_id`, `title`, `content`, `created_at`) VALUES
(6, 'ISSUE', 6, 1, 1, 4, 2, '대시보드 로딩 시 500 에러 발생', '에이치솔루션 운영 서버에서 간헐적으로 대시보드 진입 시 500 에러가 발생합니다. 빠른 확인 부탁드려요.', DATE_SUB(NOW(), INTERVAL 2 DAY)),
(7, 'ISSUE', 8, 2, 2, 2, 3, '통계 데이터 엑셀 다운로드 기능 문의', '미래소프트입니다. 월간 보고서 작성을 위해 통계 데이터를 엑셀로 받을 수 있는 방법이 있나요?', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(8, 'ISSUE', 10, 3, 3, 3, 2, '신규 입사자 계정 생성 요청', '케이텍 최신입 사원의 계정 생성이 필요합니다. 권한은 일반회원으로 설정해 주세요.', DATE_SUB(NOW(), INTERVAL 10 DAY)),
(9, 'ISSUE', 12, 1, 4, 1, 3, '모바일 웹 폰트 가독성 개선 요청', '파트너스입니다. 모바일 환경에서 폰트가 너무 작아 보입니다. 조금 키워주실 수 있을까요?', DATE_SUB(NOW(), INTERVAL 12 DAY)),
(10, 'ISSUE', 14, 1, 1, 4, 2, '결제 연동 API 타임아웃 오류', '네트웍스 결제 모듈 호출 시 60초 이상 지연되다가 타임아웃이 납니다. 확인 시급!', DATE_SUB(NOW(), INTERVAL 15 DAY)),
(11, 'ISSUE', 7, 2, 1, 2, 1, '로그인 세션 유지 시간 연장 요청', '로그인 후 30분이면 풀리는데, 업무 효율을 위해 2시간 정도로 늘려주세요.', DATE_SUB(NOW(), INTERVAL 20 DAY)),
(12, 'ISSUE', 9, 2, 2, 2, 3, '사용자 검색 필터 작동 안 함', '이름으로 검색해도 결과가 나오지 않습니다. 이전에는 잘 됐는데 확인 부탁드립니다.', DATE_SUB(NOW(), INTERVAL 25 DAY)),
(13, 'ISSUE', 11, 3, 1, 3, 2, '이미지 업로드 시 파일명 깨짐 현상', '한글 파일명을 가진 이미지를 올리면 파일명이 알 수 없는 문자로 나옵니다.', DATE_SUB(NOW(), INTERVAL 30 DAY)),
(14, 'ISSUE', 13, 1, 3, 2, 3, '관리자 권한 승인 대기', '새로 가입했는데 아직 승인 대기 중입니다. 빠른 승인 부탁드려요.', DATE_SUB(NOW(), INTERVAL 35 DAY)),
(15, 'ISSUE', 15, 2, 4, 1, 1, '다크모드 설정 유지 안 됨', '새로고침하면 다시 라이트모드로 돌아갑니다. 설정 저장이 안 되는 것 같아요.', DATE_SUB(NOW(), INTERVAL 40 DAY)),
(16, 'ISSUE', 6, 1, 1, 4, 5, 'DB 연결 실패 오류 (Critical)', 'Connection Pool이 가득 찼다는 에러와 함께 서비스가 중단되었습니다.', DATE_SUB(NOW(), INTERVAL 42 DAY)),
(17, 'ISSUE', 8, 2, 2, 2, 3, 'FAQ 카테고리 추가 요청', '협력사 전용 FAQ 카테고리가 있으면 좋겠습니다.', DATE_SUB(NOW(), INTERVAL 45 DAY)),
(18, 'ISSUE', 10, 3, 1, 3, 5, '알림 메일 발송 지연', '이슈 등록 시 담당자에게 메일이 가는 시간이 너무 늦습니다.', DATE_SUB(NOW(), INTERVAL 50 DAY)),
(19, 'ISSUE', 12, 2, 3, 2, 3, '퇴사자 계정 비활성화 처리', '홍길동 차장님이 퇴사하셔서 계정 삭제 또는 비활성화 요청합니다.', DATE_SUB(NOW(), INTERVAL 55 DAY)),
(20, 'ISSUE', 14, 1, 2, 2, 2, 'API 명세서 최신화 요청', 'v2 API 문서가 아직 업데이트되지 않은 것 같습니다.', DATE_SUB(NOW(), INTERVAL 60 DAY)),
(21, 'ISSUE', 7, 2, 1, 4, 5, '서버 용량 부족 경고', '서버 디스크 사용률이 90%를 넘었습니다. 로그 정리가 필요해 보입니다.', DATE_SUB(NOW(), INTERVAL 65 DAY)),
(22, 'ISSUE', 9, 3, 4, 2, 3, 'UI 레이아웃 깨짐 (IE11)', '특정 고객사에서 아직 IE11을 쓰는데 화면이 깨져 보인다고 합니다.', DATE_SUB(NOW(), INTERVAL 70 DAY)),
(23, 'ISSUE', 11, 1, 2, 3, 2, '글로벌 서비스 준비 관련 문의', '영문 버전 지원 계획이 있는지 궁금합니다.', DATE_SUB(NOW(), INTERVAL 75 DAY)),
(24, 'ISSUE', 13, 2, 1, 2, 3, '캐시 데이터 초기화 요청', '수정된 내용이 반영되지 않아 Redis 캐시 삭제를 요청합니다.', DATE_SUB(NOW(), INTERVAL 80 DAY)),
(25, 'ISSUE', 15, 1, 4, 1, 5, '사내 메신저 연동 문의', '슬랙이나 잔디와 연동할 수 있는 Webhook 기능이 있나요?', DATE_SUB(NOW(), INTERVAL 85 DAY))
ON DUPLICATE KEY UPDATE title=VALUES(title), content=VALUES(content), status_id=VALUES(status_id), category_id=VALUES(category_id), priority=VALUES(priority), assigned_user_id=VALUES(assigned_user_id);

-- 6. 게시글 (ARCHIVE): 5개
INSERT INTO `post` (`post_id`, `board_type`, `user_id`, `title`, `content`, `created_at`) VALUES
(26, 'ARCHIVE', 2, '2026년도 상반기 시스템 운영 리포트', '상반기 동안 발생한 주요 이슈와 대응 내역을 정리한 문서입니다.', DATE_SUB(NOW(), INTERVAL 10 DAY)),
(27, 'ARCHIVE', 3, 'IntraBoard API 연동 규격서 v2.1', '외부 시스템과의 연동을 위한 최신 API 규격서입니다. PDF 파일을 참고하세요.', DATE_SUB(NOW(), INTERVAL 20 DAY)),
(28, 'ARCHIVE', 1, '신규 입사자용 보안 서약서 양식', '모든 신규 입사자는 해당 양식을 다운로드하여 작성 후 제출해 주시기 바랍니다.', DATE_SUB(NOW(), INTERVAL 40 DAY)),
(29, 'ARCHIVE', 2, '네트워크 보안 설정 체크리스트', '고객사 설치 시 반드시 확인해야 할 보안 항목들입니다.', DATE_SUB(NOW(), INTERVAL 60 DAY)),
(30, 'ARCHIVE', 1, '사내 표준 폰트 및 BI 디자인 가이드', '일관된 UI/UX를 위한 사내 디자인 가이드라인 자료입니다.', DATE_SUB(NOW(), INTERVAL 80 DAY))
ON DUPLICATE KEY UPDATE title=VALUES(title), content=VALUES(content);

-- 7. 댓글 (comment): 이슈별 2~3개, 대댓글 포함
INSERT INTO `comment` (`comment_id`, `post_id`, `user_id`, `parent_id`, `content`, `created_at`) VALUES
(1, 6, 2, NULL, '해당 현상 현재 확인 중입니다. 로그 분석 후 다시 공유드릴게요.', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(2, 6, 6, 1, '감사합니다. 최대한 빠른 조치 부탁드려요.', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(3, 6, 1, NULL, '이 건은 서버 인스턴스 부족 문제로 보여 스케일 아웃 진행했습니다.', DATE_SUB(NOW(), INTERVAL 12 HOUR)),
(4, 7, 3, NULL, '메뉴 우측 상단에 [내보내기] 버튼을 누르시면 엑셀 다운로드가 가능합니다.', DATE_SUB(NOW(), INTERVAL 4 DAY)),
(5, 7, 8, 4, '앗, 제가 못 찾았었네요. 답변 감사합니다!', DATE_SUB(NOW(), INTERVAL 3 DAY)),
(6, 8, 2, NULL, '계정 생성 완료되었습니다. 메일로 임시 비밀번호 발송했습니다.', DATE_SUB(NOW(), INTERVAL 9 DAY)),
(7, 10, 5, NULL, '네트워크 팀 확인 결과 방화벽 정책 이슈였습니다. 현재 해제 완료되었습니다.', DATE_SUB(NOW(), INTERVAL 14 DAY)),
(8, 10, 14, 7, '확인했습니다. 이제 정상적으로 호출되네요.', DATE_SUB(NOW(), INTERVAL 13 DAY)),
(9, 13, 2, NULL, '서버 인코딩 설정 문제로 확인되었습니다. 수정 반영하겠습니다.', DATE_SUB(NOW(), INTERVAL 28 DAY)),
(10, 16, 1, NULL, '긴급 조치 완료되었습니다. 전체 재시작 진행했습니다.', DATE_SUB(NOW(), INTERVAL 41 DAY)),
(11, 16, 5, 10, '고생하셨습니다!', DATE_SUB(NOW(), INTERVAL 40 DAY))
ON DUPLICATE KEY UPDATE content=VALUES(content);

-- 8. FAQ: 5개
INSERT INTO `faq` (`faq_id`, `question`, `answer`, `sort_order`) VALUES
(1, '비밀번호를 잊어버렸어요. 어떻게 하나요?', '로그인 화면의 [비밀번호 찾기] 기능을 이용하시거나, 소속 회사의 관리자에게 초기화 요청을 해주시기 바랍니다.', 1),
(2, '파일 업로드 용량 제한이 있나요?', '게시글당 최대 100MB까지 업로드가 가능하며, 개별 파일은 20MB를 초과할 수 없습니다.', 2),
(3, '이슈 진행 상태의 기준이 궁금합니다.', '- 진행중: 담당자가 확인하고 처리 중인 상태\n- 완료: 처리가 끝난 상태\n- 미해결: 처리가 불가능하거나 보류된 상태', 3),
(4, '권한 변경은 어디서 신청하나요?', '본사 관리자(admin)에게 요청하시거나, 1:1 문의를 통해 신청 내용을 남겨주세요.', 4),
(5, '모바일에서도 이용 가능한가요?', '네, IntraBoard는 반응형 웹을 지원하여 스마트폰 및 태블릿에서도 모든 기능을 동일하게 이용하실 수 있습니다.', 5)
ON DUPLICATE KEY UPDATE question=VALUES(question), answer=VALUES(answer), sort_order=VALUES(sort_order);
