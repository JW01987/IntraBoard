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
    private String companyName; // 소속 회사명
    private Integer role;
    private LocalDateTime createdAt;
}
