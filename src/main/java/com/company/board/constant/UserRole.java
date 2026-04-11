package com.company.board.constant;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum UserRole {
    ADMIN(1, "슈퍼관리자"),
    MEMBER(2, "일반회원");

    private final int code;
    private final String label;

    public static boolean isAdmin(Integer role) {
        return role != null && role == ADMIN.code;
    }
}
