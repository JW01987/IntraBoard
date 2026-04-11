package com.company.board.controller;

import com.company.board.common.ApiResponse;
import com.company.board.constant.UserRole;
import com.company.board.domain.Comment;
import com.company.board.domain.User;
import com.company.board.service.CommentService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/comments")
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;

    // 1. 특정 게시물의 댓글 가져오기 (정렬되어 있음)
    // 주소 예시: GET /api/comments/post/10
    @GetMapping("/post/{postId}")
    public ResponseEntity<ApiResponse<List<Comment>>> getComments(@PathVariable("postId") Long postId) {
        List<Comment> comments = commentService.getCommentsByPostId(postId);
        return ResponseEntity.ok(ApiResponse.success("댓글 목록 조회 성공", comments));
    }

    // 2. 댓글 작성
    @PostMapping
    public ResponseEntity<ApiResponse<Void>> createComment(@RequestBody Comment comment, HttpServletRequest request) {
        // [정보 획득] 무사통과했으니 세션에서 꺼내기만 하면 됨
        User loginUser = (User) request.getSession(false).getAttribute("LOGIN_USER");
        comment.setUserId(loginUser.getUserId()); 

        commentService.createComment(comment);
        return ResponseEntity.ok(ApiResponse.success("댓글이 등록되었습니다."));
    }

    // 3. 댓글 삭제 (소프트 딜리트)
    @DeleteMapping("/{commentId}")
    public ResponseEntity<ApiResponse<Void>> deleteComment(@PathVariable("commentId") Long commentId, HttpServletRequest request) {
        Comment target = commentService.getComment(commentId);
        User loginUser = (User) request.getSession(false).getAttribute("LOGIN_USER");

        // 본인(작성자)이 아니면서 관리자(role=1)도 아니라면 에러
        if (!target.getUserId().equals(loginUser.getUserId()) && !UserRole.isAdmin(loginUser.getRole())) {
            return ResponseEntity.status(403).body(ApiResponse.error("댓글을 삭제할 권한이 없습니다."));
        }

        commentService.deleteComment(commentId);
        return ResponseEntity.ok(ApiResponse.success("댓글이 삭제되었습니다."));
    }
}
