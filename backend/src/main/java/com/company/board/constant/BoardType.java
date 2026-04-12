package com.company.board.constant;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum BoardType {
    NOTICE("NOTICE"),   // 공지사항
    ISSUE("ISSUE"),     // 이슈/문의
    ARCHIVE("ARCHIVE"); // 자료실

    private final String value;
}
