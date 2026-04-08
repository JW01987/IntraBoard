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
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private List<PostFile> files;
}
