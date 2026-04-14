package com.company.board.mapper;

import org.apache.ibatis.annotations.Mapper;
import java.util.List;
import java.util.Map;

@Mapper
public interface AdminMapper {
    // 핵심 지표 요약
    int getTotalPostCount();
    int getInProgressCount();
    int getDoneCount();
    int getEmergencyCount();

    // 상태별 게시글 통계
    List<Map<String, Object>> getPostStatusStats();
    
    // 중요도별 게시글 통계
    List<Map<String, Object>> getPostPriorityStats();
    
    // 카테고리별 통계
    List<Map<String, Object>> getPostCategoryStats();
}
