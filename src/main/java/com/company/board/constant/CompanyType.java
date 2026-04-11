package com.company.board.constant;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum CompanyType {
    HQ(1, "본사"),
    CLIENT(2, "고객사");

    private final int code;
    private final String label;
}
