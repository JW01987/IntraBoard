package com.company.board.common;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class ApiResponse<T> {
    private boolean success;
    private String message;
    private T data;

    // 1. 성공했을 때 (응답 데이터가 있는 경우)
    // 반환값은  ApiResponse<T>
    // 앞의 <T>는 제네릭을 사용하겠다는 선언
    public static <T> ApiResponse<T> success(String message, T data) {
        return new ApiResponse<>(true, message, data);
    }

    // 2. 성공했지만 메세지만 보낼 때 (데이터 없음)
    // 예: "회원가입 완료" 메세지만 보여줄 때 씀
    public static <T> ApiResponse<T> success(String message) {
        return new ApiResponse<>(true, message, null);
    }

    // 3. 실패(에러)가 났을 때
    public static <T> ApiResponse<T> error(String message) {
        return new ApiResponse<>(false, message, null);
    }
}
