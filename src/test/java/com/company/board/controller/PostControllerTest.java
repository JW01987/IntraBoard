package com.company.board.controller;

import com.company.board.config.LoginCheckInterceptor;
import com.company.board.domain.Post;
import com.company.board.service.PostService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// 가상의 웹브라우저
@WebMvcTest(PostController.class)
class PostControllerTest {

    // 가상의 HTTP 요청(GET/POST/..등)을 날릴 수 있게 해줌
    @Autowired
    private MockMvc mockMvc; 

    // 컨트롤러 안에 들어갈 가짜(Mock) 객체를 스프링 컨테이너에 등록
    @MockBean
    private PostService postService;

    // 인터셉터도 가짜로 등록
    @MockBean
    private LoginCheckInterceptor loginCheckInterceptor;

    @Test
    @DisplayName("MockMvc를 이용한 가상의 HTTP GET 요청으로 게시물 응답을 검증한다")
    void testGetPostById() throws Exception {
        
        Long targetPostId = 1L;
        Post fakePost = new Post();
        fakePost.setPostId(targetPostId);
        fakePost.setTitle("MockMvc 응답 테스트");

        // 인터셉터 무시
        when(loginCheckInterceptor.preHandle(any(), any(), any())).thenReturn(true);
        // 컨트롤러에서 postService.getPostDetail(1L) 호출하면 fakePost 리턴
        when(postService.getPostDetail(targetPostId)).thenReturn(fakePost);


        // 가상의 웹브라우저로 HTTP GET 요청
        mockMvc.perform(get("/api/posts/" + targetPostId)
                .contentType(MediaType.APPLICATION_JSON)) 
                
                // HTTP 응답 상태 코드가 200 인지
                // andExpect: 검증
                .andExpect(status().isOk())
                
                // 응답메세지가 "상세 조회 성공" 인지
                .andExpect(jsonPath("$.message").value("상세 조회 성공"))
                
                // 응답데이터의 제목이 "MockMvc 응답 테스트" 인지
                .andExpect(jsonPath("$.data.title").value("MockMvc 응답 테스트"));

        // postService.getPostDetail() 함수가 진짜로 1번 호출되었는지 확인
        verify(postService, times(1)).getPostDetail(targetPostId);
    }
}
