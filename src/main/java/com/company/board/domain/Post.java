package com.company.board.domain;

import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
public class Post {
    private Long postId;
    private Long userId;
    private Integer statusId; //상태값
    private String title;
    private String content;
    private Integer viewCount; //조회수
    private Boolean isDeleted;
    private String authorName; // JOIN 시 가져올 유저명
    private String authorCompany; // JOIN 시 가져올 회사명
    private Integer authorRole; // JOIN 시 가져올 유저 권한 (1:관리자, 2:본사...)
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private List<PostFile> files;
}
