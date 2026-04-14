package com.company.board.controller;

import com.company.board.common.ApiResponse;
import com.company.board.constant.UserRole;
import com.company.board.domain.User;
import com.company.board.mapper.AdminMapper;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminMapper adminMapper;

    @GetMapping("/dashboard")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDashboardStats(HttpServletRequest request) {
        
        // 권한 방어벽
        User loginUser = (User) request.getSession(false).getAttribute("LOGIN_USER");
        if (!UserRole.isAdmin(loginUser.getRole())) {
            return ResponseEntity.status(403).body(ApiResponse.error("접근 권한이 없습니다. (슈퍼관리자 전용)"));
        }

        Map<String, Object> result = new HashMap<>();
        result.put("totalPosts", adminMapper.getTotalPostCount());
        result.put("inProgressIssues", adminMapper.getInProgressCount());
        result.put("doneIssues", adminMapper.getDoneCount());
        result.put("emergencyIssues", adminMapper.getEmergencyCount());
        result.put("statusStats", adminMapper.getPostStatusStats());
        result.put("priorityStats", adminMapper.getPostPriorityStats());
        result.put("categoryStats", adminMapper.getPostCategoryStats());
        
        return ResponseEntity.ok(ApiResponse.success("대시보드 통계 조회 성공", result));
    }
}
