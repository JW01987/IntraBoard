package com.company.board.controller;

import com.company.board.common.ApiResponse;
import com.company.board.constant.UserRole;
import com.company.board.domain.Notice;
import com.company.board.domain.User;
import com.company.board.service.NoticeService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notices")
@RequiredArgsConstructor
public class NoticeController {

    private final NoticeService noticeService;

    // 1. 공지사항 목록 조회 (누구나 가능)
    @GetMapping
    public ResponseEntity<ApiResponse<List<Notice>>> getNotices() {
        List<Notice> notices = noticeService.getNoticeList();
        return ResponseEntity.ok(ApiResponse.success("공지사항 목록 조회 성공", notices));
    }

    // 2. 공지사항 상세 조회 (누구나 가능)
    @GetMapping("/{noticeId}")
    public ResponseEntity<ApiResponse<Notice>> getNoticeById(@PathVariable("noticeId") Long noticeId) {
        Notice notice = noticeService.getNoticeDetail(noticeId);
        return ResponseEntity.ok(ApiResponse.success("공지사항 조회 성공", notice));
    }

    // 3. 공지사항 작성 (오직 관리자만!)
    @PostMapping
    public ResponseEntity<ApiResponse<Void>> createNotice(@RequestBody Notice notice, HttpServletRequest request) {
        User loginUser = (User) request.getSession(false).getAttribute("LOGIN_USER");
        if (!UserRole.isAdmin(loginUser.getRole())) {
            return ResponseEntity.status(403).body(ApiResponse.error("공지사항은 관리자만 작성할 수 있습니다."));
        }
        
        notice.setUserId(loginUser.getUserId());
        noticeService.createNotice(notice);
        return ResponseEntity.ok(ApiResponse.success("공지사항이 성공적으로 등록되었습니다."));
    }

    // 4. 공지사항 수정 (관리자만)
    @PutMapping("/{noticeId}")
    public ResponseEntity<ApiResponse<Void>> updateNotice(@PathVariable("noticeId") Long noticeId, @RequestBody Notice notice, HttpServletRequest request) {
        User loginUser = (User) request.getSession(false).getAttribute("LOGIN_USER");
        if (!UserRole.isAdmin(loginUser.getRole())) {
            return ResponseEntity.status(403).body(ApiResponse.error("공지사항 수정 권한이 없습니다."));
        }

        notice.setNoticeId(noticeId);
        noticeService.updateNotice(notice);
        return ResponseEntity.ok(ApiResponse.success("공지사항 수정 완료"));
    }

    // 5. 공지사항 삭제 (관리자만)
    @DeleteMapping("/{noticeId}")
    public ResponseEntity<ApiResponse<Void>> deleteNotice(@PathVariable("noticeId") Long noticeId, HttpServletRequest request) {
        User loginUser = (User) request.getSession(false).getAttribute("LOGIN_USER");
        if (!UserRole.isAdmin(loginUser.getRole())) {
            return ResponseEntity.status(403).body(ApiResponse.error("공지사항 삭제 권한이 없습니다."));
        }

        noticeService.deleteNotice(noticeId);
        return ResponseEntity.ok(ApiResponse.success("공지사항이 삭제되었습니다."));
    }
}
