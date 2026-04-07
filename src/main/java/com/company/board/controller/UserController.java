package com.company.board.controller;

import com.company.board.domain.User;
import com.company.board.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.company.board.common.ApiResponse;

@RestController // 이 클래스의 모든 함수는 JSON 데이터로 프론트엔드에 응답을 줍니다. (REST API)
@RequestMapping("/api/users") // 모든 API는 공통적으로 http://localhost:8080/api/users 주소 뼈대를 가짐 (Router와 비슷)
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    // 1. 회원가입 API
    // @RequestBody: 전달 받은 Body를 User 객체에 담기 (JSON -> Java) flutter의 toJson과 비슷
    @PostMapping("/register")
    public ResponseEntity<ApiResponse<Void>> register(@RequestBody User user) {
        userService.registerUser(user);
        return ResponseEntity.ok(ApiResponse.success("회원가입이 완료되었습니다!"));
    }

    // 2. 로그인 API (세션 기반)
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<User>> login(@RequestBody User loginUser, HttpServletRequest request) {
        // 아이디와 비밀번호만 꺼내서 서비스 로직으로 검사
        User user = userService.login(loginUser.getLoginId(), loginUser.getPassword());

        if (user != null) {
            user.setPassword(null);

            // 세션 생성
            HttpSession session = request.getSession(); // 없으면 알아서 새로 만듦
            session.setAttribute("LOGIN_USER", user);

            return ResponseEntity.ok(ApiResponse.success("로그인 성공", user));
        } else {
            return ResponseEntity.status(401).body(ApiResponse.error("아이디 또는 비밀번호가 일치하지 않습니다."));
        }
    }

    // 3. 로그아웃 API
    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(HttpServletRequest request) {
        // request.getSession(false) : 캐비넷이 있으면 꺼내오고, 아예 접속한 적이 없어 없으면 새로 만들지 않는다!
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.invalidate(); // 세션 삭제
        }
        return ResponseEntity.ok(ApiResponse.success("로그아웃 되었습니다."));
    }
}
