package com.company.board.domain;

import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Getter
@Setter
public class PostFile {
    private Long fileId;
    private Long postId;
    private String originalName;
    private String savedName;
    private String filePath;
    private Long fileSize;
    private LocalDateTime createdAt;
}
