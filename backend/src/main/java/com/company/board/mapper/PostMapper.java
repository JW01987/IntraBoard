package com.company.board.mapper;

import com.company.board.domain.Post;
import com.company.board.domain.PostSearchDto;
import org.apache.ibatis.annotations.Mapper;
import java.util.List;

@Mapper
public interface PostMapper {
    // 1. 게시글 작성 (Create)
    void save(Post post);

    // 2. 게시물 단건 상세 조회 (Read)
    Post findById(Long postId);

    // 3. 다중 조건 검색 및 페이징 적용된 목록 조회 (Read)
    List<Post> findAll(PostSearchDto searchDto);

    // 4. 총 게시글 갯수
    int countAll(PostSearchDto searchDto);

    // 5. 게시글 수정 (Update)
    void update(Post post);

    // 6. 게시글 삭제 (Delete)
    void deleteById(Long postId);

    // 7. 조회수 1 증가
    void increaseViewCount(Long postId);
}
