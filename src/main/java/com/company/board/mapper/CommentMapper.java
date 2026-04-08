package com.company.board.mapper;

import com.company.board.domain.Comment;
import org.apache.ibatis.annotations.Mapper;
import java.util.List;

@Mapper
public interface CommentMapper {
    // 1. 댓글 / 대댓글 저장
    void save(Comment comment);
    
    // 2. 게시글 번호로 댓글 목록 가져오기
    List<Comment> findByPostId(Long postId);

    // 3. 댓글 단건 조회
    Comment findById(Long commentId);

    // 4. 댓글 수정
    void update(Comment comment);

    // 5. 삭제
    void deleteById(Long commentId);
}
