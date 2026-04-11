package com.company.board.constant;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum Priority {
    LOW(1, "낮음"),
    NORMAL(2, "보통"),
    HIGH(3, "높음"),
    URGENT(4, "긴급");

    private final int code;
    private final String label;
}
