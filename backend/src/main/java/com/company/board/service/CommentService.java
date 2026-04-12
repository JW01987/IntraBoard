package com.company.board.service;

import com.company.board.domain.Comment;
import com.company.board.mapper.CommentMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CommentService {
    
    private final CommentMapper commentMapper;

    // 1. 댓글 생성
    public void createComment(Comment comment) {
        commentMapper.save(comment);
    }

    // 2. 게시글에 따른 댓글 가져오기
    public List<Comment> getCommentsByPostId(Long postId) {
        return commentMapper.findByPostId(postId);
    }

    // 3. 댓글 단건 조회
    public Comment getComment(Long commentId) {
        return commentMapper.findById(commentId);
    }
    
    // 4. 댓글 수정
    public void updateComment(Comment comment) {
        commentMapper.update(comment);
    }

    // 5. 댓글 삭제
    public void deleteComment(Long commentId) {
        commentMapper.deleteById(commentId);
    }
}
