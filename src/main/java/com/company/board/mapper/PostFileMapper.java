package com.company.board.mapper;

import com.company.board.domain.PostFile;
import org.apache.ibatis.annotations.Mapper;
import java.util.List;

@Mapper
public interface PostFileMapper {
    void save(PostFile postFile);
    List<PostFile> findByPostId(Long postId);
    void deleteById(Long fileId);
}
