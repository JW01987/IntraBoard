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
    private LocalDateTime createdAt;
}
