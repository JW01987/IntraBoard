package com.company.board.config;

import com.company.board.common.ApiResponse;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
public class LoginCheckInterceptor implements HandlerInterceptor {

    // 컨트롤러 실행 전 실행
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("LOGIN_USER") == null) {
            
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED); // 401 
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            
            // 객체 변환 라이브러리 에러를 방지하기 위해 가벼운 수동 JSON 문자열을 만들어줍니다.
            String errorJson = "{\"success\": false, \"message\": \"로그인이 필요한 서비스입니다.\", \"data\": null}";
            response.getWriter().write(errorJson);
            
            return false; // 컨트롤러 진입 불가
        }
        
        return true; // 컨트롤러 진입 허용
    }
}
