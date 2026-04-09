package com.company.board.service;

import com.company.board.domain.Post;
import com.company.board.mapper.PostFileMapper;
import com.company.board.mapper.PostMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

// 단위 테스트
// DB 연결 없음, 비즈니스 로직만 검증
@ExtendWith(MockitoExtension.class)
class PostServiceTest {

    // 가짜 객체(Mock): 가짜 DB 매퍼
    @Mock
    private PostMapper postMapper;

    @Mock
    private PostFileMapper postFileMapper;

    // 테스트 대상: 가짜 매퍼들을 주입(Inject)받은 PostService 객체
    @InjectMocks
    private PostService postService;

    @Test
    @DisplayName("게시글 상세조회 시 (1)조회수 증가와 (2)데이터 조회가 완벽하게 실행되어야 한다")
    void testGetPostDetail() {
        
        // Mock 데이터 세팅
        Long targetPostId = 99L; //Long타입 명시
        Post testPost = new Post();
        testPost.setPostId(targetPostId);
        testPost.setTitle("테스트용 코딩 제목");

        // 매퍼에 설정 아이디 요청시 -> testPost리턴
        when(postMapper.findById(targetPostId)).thenReturn(testPost);

        // 실행 단계
        Post result = postService.getPostDetail(targetPostId);

        // 검증 단계
        // 1. 가져온 데이터가 정상적인가?
        assertNotNull(result, "게시글이 나와야 합니다."); // asserNotNull -> null이 아니어야함
        assertEquals("테스트용 코딩 제목", result.getTitle()); // assertEquals -> 값이 같아야함

        // 2. 서비스 로직 안에서 조회수 증가 함수를 안 빼먹고 성실하게 "1번" 실행했는가?
        verify(postMapper, times(1)).increaseViewCount(targetPostId); // verify -> 함수가 호출되었는지 확인
        
        // 3. findById 함수도 성실하게 "1번" 실행했는가?
        verify(postMapper, times(1)).findById(targetPostId);
    }
}
