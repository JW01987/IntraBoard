package com.company.board.mapper;

import com.company.board.domain.PostFile;
import org.apache.ibatis.annotations.Mapper;
import java.util.List;

@Mapper
public interface PostFileMapper {
    // 1. 파일 저장
    void save(PostFile postFile);
    
    // 2. 게시글 번호로 파일 목록 조회
    List<PostFile> findByPostId(Long postId);
    
    // 3. 파일 삭제
    void deleteById(Long fileId);
}
