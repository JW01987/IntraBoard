package com.company.board.controller;

import com.company.board.common.ApiResponse;
import com.company.board.domain.Post;
import com.company.board.domain.PostSearchDto;
import com.company.board.domain.User;
import com.company.board.service.PostService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/posts")
@RequiredArgsConstructor
public class PostController {

    private final PostService postService;

    // 1. 게시글 목록 조회 (검색+페이징)
    // @ModelAttribute: 파라미터를 PostSearchDto로 알아서 적용
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getPosts(@ModelAttribute PostSearchDto searchDto) {
        Map<String, Object> pageResult = postService.getPostList(searchDto);
        return ResponseEntity.ok(ApiResponse.success("게시글 목록 조회 성공", pageResult));
    }

    // 2. 게시글 상세 조회
    @GetMapping("/{postId}")
    public ResponseEntity<ApiResponse<Post>> getPostById(@PathVariable("postId") Long postId) {
        Post post = postService.getPostDetail(postId);
        return ResponseEntity.ok(ApiResponse.success("상세 조회 성공", post));
    }

    // 3. 게시글 작성
    @PostMapping
    public ResponseEntity<ApiResponse<Void>> createPost(@RequestBody Post post, HttpServletRequest request) {
        // 세션 검증
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("LOGIN_USER") == null) {
            return ResponseEntity.status(401).body(ApiResponse.error("로그인이 필요합니다."));
        }

        // 로그인한 유저만 통과! 내 정보 꺼내기
        User loginUser = (User) session.getAttribute("LOGIN_USER");
        
        // 프론트엔드가 혹시 userId를 조작해서 보낼 수도 있으니, 무시하고 서버 세션에 있는 내 ID로 강제로 덮어씌웁니다. (보안)
        post.setUserId(loginUser.getUserId()); 

        // 만약 상태값이 안 들어왔으면 1번(진행중)으로 기본 세팅
        if (post.getStatusId() == null) {
            post.setStatusId(1); 
        }

        postService.createPost(post);
        return ResponseEntity.ok(ApiResponse.success("글이 성공적으로 등록되었습니다."));
    }

    // 4. 게시글 수정
    @PutMapping("/{postId}")
    public ResponseEntity<ApiResponse<Void>> updatePost(@PathVariable("postId") Long postId, @RequestBody Post post) {
        post.setPostId(postId);
        postService.updatePost(post);
        return ResponseEntity.ok(ApiResponse.success("게시글 수정 완료"));
    }

    // 5. 게시글 삭제 (소프트 딜리트 상태 처리)
    @DeleteMapping("/{postId}")
    public ResponseEntity<ApiResponse<Void>> deletePost(@PathVariable("postId") Long postId) {
        postService.deletePost(postId);
        return ResponseEntity.ok(ApiResponse.success("게시글이 삭제되었습니다."));
    }
}
