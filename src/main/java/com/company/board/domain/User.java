package com.company.board.domain;

import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Getter
@Setter
public class User {
    private Long userId;
    private String loginId;
    private String password;
    private String name;
    private Integer role;
    private LocalDateTime createdAt;
}
