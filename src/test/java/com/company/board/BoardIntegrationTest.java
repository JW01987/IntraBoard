package com.company.board;

import com.company.board.domain.*;
import com.company.board.mapper.AdminMapper;
import com.company.board.mapper.CompanyMapper;
import com.company.board.service.NoticeService;
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
    @Autowired NoticeService noticeService;
    @Autowired CompanyMapper companyMapper;
    @Autowired AdminMapper adminMapper;

    // ============================================================
    // 시나리오 전체 흐름
    // 1. 관리자가 새 고객사 등록
    // 2. 각 소속의 유저 회원가입
    // 3. 공지사항 작성 (관리자 전용)
    // 4. 일반 직원이 카테고리/중요도 설정하여 게시글 작성
    // 5. 각종 검색 필터 검증
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
        admin.setCompanyId(1L); // schema.sql 에 자동생성된 "(주)보드본사"(company_id=1)
        admin.setRole(1); // 슈퍼관리자
        userService.registerUser(admin);

        User client = new User();
        client.setLoginId("testclient_" + System.currentTimeMillis());
        client.setPassword("client123");
        client.setName("고객사직원A");
        client.setCompanyId(newClient.getCompanyId()); // 방금 만든 삼성고객사 소속
        client.setRole(2); // 일반회원
        userService.registerUser(client);

        assertNotNull(admin.getUserId(), "관리자 PK 발급 확인");
        assertNotNull(client.getUserId(), "고객사직원 PK 발급 확인");

        // 비밀번호는 암호화되어 저장되었으므로 평문과 달라야 함
        assertThat(userService.getUserById(admin.getUserId()).getPassword())
                .isNotEqualTo("secret123");


        // ==========================================
        // Step 3. 공지사항 작성 (관리자 전용)
        // ==========================================
        Notice notice = new Notice();
        notice.setUserId(admin.getUserId());
        notice.setTitle("4월 전체 회의 공지");
        notice.setContent("다음 주 월요일 오전 10시 필참 바랍니다.");
        noticeService.createNotice(notice);

        List<Notice> notices = noticeService.getNoticeList();
        assertThat(notices).isNotEmpty();
        // 내가 방금 추가한 공지사항이 목록 최상단에 있어야 함 (ORDER BY notice_id DESC)
        assertThat(notices.get(0).getTitle()).contains("4월");
        assertThat(notices.get(0).getAuthorName()).isEqualTo("테스트관리자"); // 조인 확인
        assertThat(notices.get(0).getAuthorCompany()).isEqualTo("(주)보드본사"); // 회사 조인 확인


        // ==========================================
        // Step 4. 고객사 직원이 카테고리/중요도 포함 게시글 3개 작성
        // ==========================================
        Post bugPost = new Post();
        bugPost.setUserId(client.getUserId());
        bugPost.setCategoryId(1L);  // 1: 버그/오류 (schema.sql 기본값)
        bugPost.setPriority(4);     // 4: 긴급
        bugPost.setTitle("[긴급] 로그인 페이지 500 에러");
        bugPost.setContent("로그인 시도 시 500 Internal Server Error 발생합니다.");
        bugPost.setStatusId(1);     // 진행중
        postService.createPost(bugPost);

        Post inquiryPost = new Post();
        inquiryPost.setUserId(client.getUserId());
        inquiryPost.setCategoryId(2L); // 2: 기능문의
        inquiryPost.setPriority(2);    // 2: 보통
        inquiryPost.setTitle("검색 필터 추가 가능한가요?");
        inquiryPost.setContent("기간별 검색 기능이 필요합니다.");
        inquiryPost.setStatusId(1);
        postService.createPost(inquiryPost);

        Post donePost = new Post();
        donePost.setUserId(admin.getUserId());
        donePost.setCategoryId(3L);  // 3: 계정/권한
        donePost.setPriority(1);     // 1: 낮음
        donePost.setTitle("초기 계정 세팅 완료");
        donePost.setContent("초기 어드민 계정 세팅이 완료되었습니다.");
        donePost.setStatusId(2);     // 완료
        postService.createPost(donePost);


        // ==========================================
        // Step 5. 검색 필터 시나리오 검증
        // ==========================================

        // 5-1. 카테고리 필터 (버그/오류만 1개 나와야 함)
        PostSearchDto bugFilter = new PostSearchDto();
        bugFilter.setCategoryId(1L);
        Map<String, Object> bugResult = postService.getPostList(bugFilter);
        List<Post> bugPosts = (List<Post>) bugResult.get("list");
        assertThat(bugPosts).hasSize(1);
        assertThat(bugPosts.get(0).getCategoryName()).isEqualTo("버그/오류"); // 카테고리 조인 확인
        assertThat(bugPosts.get(0).getAuthorCompany()).isEqualTo("삼성고객사"); // 고객사 조인 확인

        // 5-2. 상태 필터 (완료 = statusId:2, 1개 나와야 함)
        PostSearchDto doneFilter = new PostSearchDto();
        doneFilter.setStatusId(2);
        Map<String, Object> doneResult = postService.getPostList(doneFilter);
        List<Post> donePosts = (List<Post>) doneResult.get("list");
        assertThat(donePosts).hasSize(1);
        assertThat(donePosts.get(0).getTitle()).contains("완료");

        // 5-3. 중요도 필터 (긴급=4, 1개 나와야 함)
        PostSearchDto urgentFilter = new PostSearchDto();
        urgentFilter.setPriority(4);
        Map<String, Object> urgentResult = postService.getPostList(urgentFilter);
        List<Post> urgentPosts = (List<Post>) urgentResult.get("list");
        assertThat(urgentPosts).hasSize(1);
        assertThat(urgentPosts.get(0).getTitle()).contains("긴급");

        // 5-4. 회사별 필터 (삼성고객사=newClientId, 2개 나와야 함)
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
        assertThat(namePosts).hasSize(1);

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
