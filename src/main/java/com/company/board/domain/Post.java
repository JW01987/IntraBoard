package com.company.board.domain;

import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
public class Post {
    private Long postId;
    private Long userId; // 작성자
    private Integer statusId; // 진행상태
    private Long categoryId; // 게시글 분류 (버그, 오류 등)
    private Integer priority; // 1:낮음, 2:보통, 3:높음, 4:긴급
    private Long assignedUserId; // 배정된 담당자 (본사 직원)
    
    private String title;
    private String content;
    private Integer viewCount; //조회수
    private Boolean isDeleted;
    private String authorName; // 조인
    private String authorCompany; // 조인
    private Integer authorRole; // 조인
    
    // 추가 조인 뷰 데이터
    private String categoryName; // 조인 
    private String assignedUserName; // 조인 (작업 할당 담당자) TODO: 추후 알림 기능 추가 예정
    
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private List<PostFile> files;
}
