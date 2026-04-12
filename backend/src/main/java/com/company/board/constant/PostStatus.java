package com.company.board.constant;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum PostStatus {
    IN_PROGRESS(1, "진행중"),
    DONE(2, "완료"),
    UNRESOLVED(3, "미해결"),
    HIDDEN(4, "숨김");

    private final int code;
    private final String label;
}
