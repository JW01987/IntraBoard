package com.company.board.controller;

import com.company.board.common.ApiResponse;
import com.company.board.constant.UserRole;
import com.company.board.domain.User;
import com.company.board.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
public class AdminUserController {

    private final UserService userService;

    // 공통 관리자 권한 체크 메서드
    private boolean isAdmin(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) return false;
        User loginUser = (User) session.getAttribute("LOGIN_USER");
        return loginUser != null && UserRole.isAdmin(loginUser.getRole());
    }

    // 1. 승인 대기 목록 조회
    @GetMapping("/pending")
    public ResponseEntity<ApiResponse<List<User>>> getPendingUsers(HttpServletRequest request) {
        if (!isAdmin(request)) {
            return ResponseEntity.status(403).body(ApiResponse.error("권한이 없습니다. (관리자 전용)"));
        }
        return ResponseEntity.ok(ApiResponse.success("승인 대기 목록 조회 성공", userService.getPendingUsers()));
    }

    // 1.5 전체 회원 목록 조회
    @GetMapping("/all")
    public ResponseEntity<ApiResponse<List<User>>> getAllUsers(HttpServletRequest request) {
        if (!isAdmin(request)) {
            return ResponseEntity.status(403).body(ApiResponse.error("권한이 없습니다. (관리자 전용)"));
        }
        return ResponseEntity.ok(ApiResponse.success("전체 회원 목록 조회 성공", userService.getAllUsers()));
    }

    // 2. 가입 승인
    @PutMapping("/{id}/approve")
    public ResponseEntity<ApiResponse<Void>> approveUser(@PathVariable("id") Long id, HttpServletRequest request) {
        if (!isAdmin(request)) {
            return ResponseEntity.status(403).body(ApiResponse.error("권한이 없습니다. (관리자 전용)"));
        }
        userService.updateUserStatus(id, 1); // 1: 활성(승인)
        return ResponseEntity.ok(ApiResponse.success("가입이 승인되었습니다."));
    }

    // 3. 가입 거절
    @PutMapping("/{id}/reject")
    public ResponseEntity<ApiResponse<Void>> rejectUser(@PathVariable("id") Long id, HttpServletRequest request) {
        if (!isAdmin(request)) {
            return ResponseEntity.status(403).body(ApiResponse.error("권한이 없습니다. (관리자 전용)"));
        }
        userService.updateUserStatus(id, 2); // 2: 거절
        return ResponseEntity.ok(ApiResponse.success("가입이 거절되었습니다."));
    }
}
