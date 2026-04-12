package com.company.board;

import com.company.board.constant.BoardType;
import com.company.board.constant.PostStatus;
import com.company.board.constant.Priority;
import com.company.board.constant.UserRole;
import com.company.board.domain.*;
import com.company.board.mapper.AdminMapper;
import com.company.board.mapper.CompanyMapper;
import com.company.board.service.PostService;
import com.company.board.service.UserService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertNotNull;

@SpringBootTest
@Transactional // DB에 넣었던 더미데이터를 모두 롤백(삭제)합니다
class BoardIntegrationTest {

    @Autowired UserService userService;
    @Autowired PostService postService;
    @Autowired CompanyMapper companyMapper;
    @Autowired AdminMapper adminMapper;

    // ============================================================
    // 시나리오 전체 흐름
    // 1. 관리자가 새 고객사 등록
    // 2. 각 소속의 유저 회원가입
    // 3. 공지사항 작성 (board_type=NOTICE)
    // 4. 일반 직원이 이슈 게시글 작성 (board_type=ISSUE)
    // 5. 각종 검색 필터 검증 (boardType 필터 포함)
    // 6. 관리자 대시보드 통계 검증
    // ============================================================

    @Test
    @DisplayName("회사 등록 → 유저 가입 → 게시글/공지사항 작성 → 검색 → 대시보드 통계 전체 흐름 통합 테스트")
    void fullScenarioTest() {
        
        // ==========================================
        // Step 1. 관리자가 신규 고객사 추가
        // ==========================================
        Company newClient = new Company();
        newClient.setCompanyName("삼성고객사");
        newClient.setCompanyType(2); // 2: 고객사
        companyMapper.save(newClient);

        assertNotNull(newClient.getCompanyId(), "고객사 저장 후 PK가 자동 발급되어야 함");

        List<Company> companies = companyMapper.findAll();
        // schema.sql의 ON DUPLICATE KEY 때문에 "(주)보드본사" 포함 최소 2개
        assertThat(companies.size()).isGreaterThanOrEqualTo(2);


        // ==========================================
        // Step 2. 유저 2명 회원가입 (각각 본사, 고객사 소속)
        // ==========================================
        User admin = new User();
        admin.setLoginId("testadmin_" + System.currentTimeMillis()); // 중복 방지용 타임스탬프
        admin.setPassword("secret123");
        admin.setName("테스트관리자");
        admin.setCompanyId(1L);
        admin.setRole(UserRole.ADMIN.getCode());
        userService.registerUser(admin);

        User client = new User();
        client.setLoginId("testclient_" + System.currentTimeMillis());
        client.setPassword("client123");
        client.setName("고객사직원A");
        client.setCompanyId(newClient.getCompanyId());
        client.setRole(UserRole.MEMBER.getCode());
        userService.registerUser(client);

        assertNotNull(admin.getUserId(), "관리자 PK 발급 확인");
        assertNotNull(client.getUserId(), "고객사직원 PK 발급 확인");

        // 비밀번호는 암호화되어 저장되었으므로 평문과 달라야 함
        assertThat(userService.getUserById(admin.getUserId()).getPassword())
                .isNotEqualTo("secret123");


        // ==========================================
        // Step 3. 공지사항 작성 (board_type = NOTICE)
        // ==========================================
        Post noticePost = new Post();
        noticePost.setBoardType(BoardType.NOTICE.getValue());
        noticePost.setUserId(admin.getUserId());
        noticePost.setTitle("4월 전체 회의 공지");
        noticePost.setContent("다음 주 월요일 오전 10시 필참 바랍니다.");
        postService.createPost(noticePost);


        // ==========================================
        // Step 4. 고객사 직원이 카테고리/중요도 포함 게시글 3개 작성
        // ==========================================
        Post bugPost = new Post();
        bugPost.setBoardType(BoardType.ISSUE.getValue());
        bugPost.setUserId(client.getUserId());
        bugPost.setCategoryId(1L);
        bugPost.setPriority(Priority.URGENT.getCode());
        bugPost.setTitle("[긴급] 로그인 페이지 500 에러");
        bugPost.setContent("로그인 시도 시 500 Internal Server Error 발생합니다.");
        bugPost.setStatusId(PostStatus.IN_PROGRESS.getCode());
        postService.createPost(bugPost);

        Post inquiryPost = new Post();
        inquiryPost.setBoardType(BoardType.ISSUE.getValue());
        inquiryPost.setUserId(client.getUserId());
        inquiryPost.setCategoryId(2L);
        inquiryPost.setPriority(Priority.NORMAL.getCode());
        inquiryPost.setTitle("검색 필터 추가 가능한가요?");
        inquiryPost.setContent("기간별 검색 기능이 필요합니다.");
        inquiryPost.setStatusId(PostStatus.IN_PROGRESS.getCode());
        postService.createPost(inquiryPost);

        Post donePost = new Post();
        donePost.setBoardType(BoardType.ISSUE.getValue());
        donePost.setUserId(admin.getUserId());
        donePost.setCategoryId(3L);
        donePost.setPriority(Priority.LOW.getCode());
        donePost.setTitle("초기 계정 세팅 완료");
        donePost.setContent("초기 어드민 계정 세팅이 완료되었습니다.");
        donePost.setStatusId(PostStatus.DONE.getCode());
        postService.createPost(donePost);


        // ==========================================
        // Step 5. 검색 필터 시나리오 검증
        // ==========================================

        // 5-1. boardType 필터 (NOTICE만 1개 나와야 함)
        PostSearchDto noticeFilter = new PostSearchDto();
        noticeFilter.setBoardType(BoardType.NOTICE.getValue());
        Map<String, Object> noticeResult = postService.getPostList(noticeFilter);
        List<Post> noticePosts = (List<Post>) noticeResult.get("list");
        assertThat(noticePosts).hasSize(1);
        assertThat(noticePosts.get(0).getTitle()).contains("4월");
        assertThat(noticePosts.get(0).getAuthorName()).isEqualTo("테스트관리자");
        assertThat(noticePosts.get(0).getAuthorCompany()).isEqualTo("(주)보드본사");

        // 5-2. boardType 필터 (ISSUE만 3개 나와야 함)
        PostSearchDto issueFilter = new PostSearchDto();
        issueFilter.setBoardType(BoardType.ISSUE.getValue());
        Map<String, Object> issueResult = postService.getPostList(issueFilter);
        List<Post> issuePosts = (List<Post>) issueResult.get("list");
        assertThat(issuePosts).hasSize(3);

        // 5-3. 카테고리 필터 (버그/오류만 1개 나와야 함)
        PostSearchDto bugFilter = new PostSearchDto();
        bugFilter.setCategoryId(1L);
        Map<String, Object> bugResult = postService.getPostList(bugFilter);
        List<Post> bugPosts = (List<Post>) bugResult.get("list");
        assertThat(bugPosts).hasSize(1);
        assertThat(bugPosts.get(0).getCategoryName()).isEqualTo("버그/오류");
        assertThat(bugPosts.get(0).getAuthorCompany()).isEqualTo("삼성고객사");

        // 5-4. 상태 필터 (완료 = statusId:2, 1개)
        PostSearchDto doneFilter = new PostSearchDto();
        doneFilter.setStatusId(PostStatus.DONE.getCode());
        Map<String, Object> doneResult = postService.getPostList(doneFilter);
        List<Post> donePosts = (List<Post>) doneResult.get("list");
        assertThat(donePosts).hasSize(1);
        assertThat(donePosts.get(0).getTitle()).contains("완료");

        // 5-5. 중요도 필터 (긴급=4, 1개)
        PostSearchDto urgentFilter = new PostSearchDto();
        urgentFilter.setPriority(Priority.URGENT.getCode());
        Map<String, Object> urgentResult = postService.getPostList(urgentFilter);
        List<Post> urgentPosts = (List<Post>) urgentResult.get("list");
        assertThat(urgentPosts).hasSize(1);
        assertThat(urgentPosts.get(0).getTitle()).contains("긴급");

        // 5-6. 회사별 필터
        PostSearchDto companyFilter = new PostSearchDto();
        companyFilter.setCompanyId(newClient.getCompanyId());
        Map<String, Object> companyResult = postService.getPostList(companyFilter);
        List<Post> companyPosts = (List<Post>) companyResult.get("list");
        assertThat(companyPosts).hasSize(2);

        // 5-5. 작성자 이름 검색
        PostSearchDto nameFilter = new PostSearchDto();
        nameFilter.setAuthorName("테스트관리자");
        Map<String, Object> nameResult = postService.getPostList(nameFilter);
        List<Post> namePosts = (List<Post>) nameResult.get("list");
        assertThat(namePosts).hasSize(2);

        // 5-6. 키워드 검색
        PostSearchDto keywordFilter = new PostSearchDto();
        keywordFilter.setKeyword("로그인");
        Map<String, Object> keywordResult = postService.getPostList(keywordFilter);
        List<Post> keywordPosts = (List<Post>) keywordResult.get("list");
        assertThat(keywordPosts).hasSize(1);
        assertThat(keywordPosts.get(0).getTitle()).contains("로그인");


        // ==========================================
        // Step 6. 관리자 대시보드 통계 확인
        // ==========================================
        List<Map<String, Object>> statusStats = adminMapper.getPostStatusStats();
        assertThat(statusStats).isNotEmpty();
        // "진행중" 2개, "완료" 1개 포함되어 있는지 확인
        long inProgressCount = statusStats.stream()
                .filter(s -> "진행중".equals(s.get("statusName")))
                .mapToLong(s -> Long.parseLong(s.get("count").toString()))
                .sum();
        assertThat(inProgressCount).isEqualTo(2);

        List<Map<String, Object>> categoryStats = adminMapper.getPostCategoryStats();
        assertThat(categoryStats).isNotEmpty();
        // "버그/오류" 1개 확인
        long bugCount = categoryStats.stream()
                .filter(s -> "버그/오류".equals(s.get("categoryName")))
                .mapToLong(s -> Long.parseLong(s.get("count").toString()))
                .sum();
        assertThat(bugCount).isEqualTo(1);
    }
}
