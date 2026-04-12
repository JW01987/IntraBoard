package com.company.board.domain;

import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Getter
@Setter
public class User {
    private Long userId; //PK
    private String loginId;
    private String password;
    private String name;
    private Long companyId; // 관계형 조인 (외래키)
    private Integer role; // 1: 슈퍼관리자(어드민), 2: 일반회원

    // JOIN 전용 데이터
    private String companyName; // JOIN 시 가져올 회사명
    private Integer companyType; // JOIN 시 가져올 회사 분류 (1: 본사, 2: 고객사)
    private LocalDateTime createdAt;
}
