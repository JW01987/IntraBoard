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
        
        // 모든 로그인 사용자가 조회 가능하도록 권한 체크 제거 (로그인 세션만 확인)
        User loginUser = (User) request.getSession(false).getAttribute("LOGIN_USER");
        if (loginUser == null) {
            return ResponseEntity.status(401).body(ApiResponse.error("로그인이 필요합니다."));
        }

        Map<String, Object> result = new HashMap<>();
        result.put("totalPosts", adminMapper.getTotalPostCount());
        result.put("inProgressIssues", adminMapper.getInProgressCount());
        result.put("doneIssues", adminMapper.getDoneCount());
        result.put("emergencyIssues", adminMapper.getEmergencyCount());
        result.put("statusStats", adminMapper.getPostStatusStats());
        result.put("priorityStats", adminMapper.getPostPriorityStats());
        result.put("categoryStats", adminMapper.getPostCategoryStats());
        
        // 본사 직원(company_type=1)인 경우에만 담당 이슈 최신 5건 반환
        if (loginUser.getCompanyType() != null && loginUser.getCompanyType() == 1) {
            result.put("assignedIssues", adminMapper.getAssignedIssues(loginUser.getUserId()));
        } else {
            result.put("assignedIssues", new java.util.ArrayList<>());
        }
        
        return ResponseEntity.ok(ApiResponse.success("대시보드 통계 조회 성공", result));
    }
}
