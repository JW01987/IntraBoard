package com.company.board.domain;

import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Getter
@Setter
public class Notice {
    private Long noticeId;
    private Long userId; // 관리자 ID
    private String title;
    private String content;
    private Integer viewCount;
    private LocalDateTime createdAt;
    
    private String authorName; // 조인
    private String authorCompany; // 조인
}
