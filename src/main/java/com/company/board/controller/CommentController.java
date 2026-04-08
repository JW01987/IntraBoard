package com.company.board.controller;

import com.company.board.common.ApiResponse;
import com.company.board.domain.Comment;
import com.company.board.domain.User;
import com.company.board.service.CommentService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/comments") // 이 컨트롤러의 시작 주소는 전부 /api/comments
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;

    // 1. 특정 게시물의 댓글 쫙 가져오기 (정렬되어 있음)
    // 주소 예시: GET /api/comments/post/10
    @GetMapping("/post/{postId}")
    public ResponseEntity<ApiResponse<List<Comment>>> getComments(@PathVariable("postId") Long postId) {
        List<Comment> comments = commentService.getCommentsByPostId(postId);
        return ResponseEntity.ok(ApiResponse.success("댓글 목록 조회 성공", comments));
    }

    // 2. 댓글 작성 (일반 댓글이든, 대댓글이든 이거 하나로 커버됨)
    @PostMapping
    public ResponseEntity<ApiResponse<Void>> createComment(@RequestBody Comment comment, HttpServletRequest request) {
        // [서버 주도 검증] 로그인 여부 쓰윽 확인
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("LOGIN_USER") == null) {
            return ResponseEntity.status(401).body(ApiResponse.error("로그인이 필요한 서비스입니다."));
        }
        
        // 내 진짜 신분증 번호를 강제로 세팅
        User loginUser = (User) session.getAttribute("LOGIN_USER");
        comment.setUserId(loginUser.getUserId()); 

        commentService.createComment(comment);
        return ResponseEntity.ok(ApiResponse.success("댓글이 등록되었습니다."));
    }

    // 3. 댓글 삭제 (소프트 딜리트)
    @DeleteMapping("/{commentId}")
    public ResponseEntity<ApiResponse<Void>> deleteComment(@PathVariable("commentId") Long commentId, HttpServletRequest request) {
        
        // 💡 실무 방어벽 포인트 💡
        // 지금은 그냥 통과시키지만, 원래는 여기서 이 행동을 막아야 합니다!
        // 1. commentService.getComment(commentId) 로 주인장의 유저 번호를 구한다.
        // 2. 세션의 내 번호(loginUser.getUserId()) 와 비교한다.
        // 3. 다르면 "야, 남의 댓글 지우지마!" 하고 403 에러로 막는다.

        commentService.deleteComment(commentId);
        return ResponseEntity.ok(ApiResponse.success("댓글이 삭제되었습니다."));
    }
}
