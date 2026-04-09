package com.company.board.domain;

import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Getter
@Setter
public class Comment {
    private Long commentId;
    private Long postId;
    private Long userId;
    private Long parentId;
    private String content;
    private Boolean isDeleted;
    private String authorName; // 조인용 이름
    private String authorCompany; // 조인용 회사명
    private Integer authorRole; // 조인용 권한
    private LocalDateTime createdAt;
}
