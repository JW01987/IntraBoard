package com.company.board.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.lang.NonNull;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.Objects;

@Configuration // 이 파일은 설정 전용 파일임을 명시
@RequiredArgsConstructor
public class WebConfig implements WebMvcConfigurer {

    private final LoginCheckInterceptor loginCheckInterceptor;

    @Override
    public void addInterceptors(@NonNull InterceptorRegistry registry) {
        // null-safety 경고(unchecked conversion)를 없애기 위해 자바 표준 검증 활용
        registry.addInterceptor(Objects.requireNonNull(loginCheckInterceptor))
                .order(1)                     // 1번째로 실행하는 interceptor
                .addPathPatterns("/api/**")   // /api 로 시작하는 모든 요청 확인
                .excludePathPatterns(
                        "/api/users/login",
                        "/api/users/register", // 회원가입, 로그인은 인증 없이 뚫려있어야 함
                        "/api/system/companies", // 회원가입 시 회사 목록 조회가 필요함
                        "/api/files/display/**", // 이미지 인라인 미리보기는 공개 (UUID 파일명으로 보안 유지)
                        "/error"
                );
    }

    // CORS 설정
    @Override
    public void addCorsMappings(@NonNull CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOriginPatterns("*") // 모든 아이피/주소에서 웹서버에 접근 허용
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS") // 허용할 요청 종류
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600); // 캐싱 시간
    }

    // Flutter에서 사진/파일을 다운로드
    @Override
    public void addResourceHandlers(@NonNull ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:uploads/");
    }
}
