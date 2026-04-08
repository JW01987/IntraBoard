package com.company.board.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration // 이 파일은 설정 전용 파일임을 명시
@RequiredArgsConstructor
public class WebConfig implements WebMvcConfigurer {

    private final LoginCheckInterceptor loginCheckInterceptor;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(loginCheckInterceptor)
                .order(1)                     // 1번째로 실행하는 interceptor
                .addPathPatterns("/api/**")   // /api 로 시작하는 모든 요청 확인
                .excludePathPatterns(
                        "/api/users/login",
                        "/api/users/register", // 회원가입, 로그인은 인증 없이 뚫려있어야 함
                        "/error"
                );
    }
}
