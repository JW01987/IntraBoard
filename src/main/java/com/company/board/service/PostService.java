package com.company.board.service;

import com.company.board.domain.Post;
import com.company.board.domain.PostSearchDto;
import com.company.board.mapper.PostMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class PostService {

    private final PostMapper postMapper;

    // 1. 게시글 작성
    public void createPost(Post post) {
        postMapper.save(post);
    }

    // 2. 게시글 상세 보기 (조회수 1 증가시키고 조회해옴)
    public Post getPostDetail(Long postId) {
        postMapper.increaseViewCount(postId);
        return postMapper.findById(postId);
    }

    // 3. 목록 검색 및 페이징 종합 처리
    public Map<String, Object> getPostList(PostSearchDto searchDto) {
        List<Post> list = postMapper.findAll(searchDto); // 1. 데이터 목록 가져오기
        int totalCount = postMapper.countAll(searchDto); // 2. 전체 개수 가져오기

        Map<String, Object> pageResult = new HashMap<>();
        pageResult.put("list", list);
        pageResult.put("totalCount", totalCount);
        pageResult.put("currentPage", searchDto.getPage());
        
        // ✨ 총 페이지 수 계산: (총 갯수 / 한 페이지당 갯수) 후 무조건 올림! 
        // 예: 21개면 3쪽이어야 함. Math.ceil(21 / 10.0) = 3
        pageResult.put("totalPages", (int) Math.ceil((double) totalCount / searchDto.getSize()));

        return pageResult;
    }

    // 4. 글 수정
    public void updatePost(Post post) {
        postMapper.update(post);
    }

    // 5. 글 삭제 (소프트 딜리트)
    public void deletePost(Long postId) {
        postMapper.deleteById(postId);
    }
}
