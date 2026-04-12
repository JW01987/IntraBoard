package com.company.board.domain;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class Company {
    private Long companyId;
    private String companyName;
    private Integer companyType; // 1: 본사, 2: 고객사
}
