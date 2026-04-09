package com.company.board.controller;

import com.company.board.common.ApiResponse;
import com.company.board.domain.Category;
import com.company.board.domain.Company;
import com.company.board.domain.User;
import com.company.board.mapper.CategoryMapper;
import com.company.board.mapper.CompanyMapper;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/system")
@RequiredArgsConstructor
public class SystemController {

    private final CompanyMapper companyMapper;
    private final CategoryMapper categoryMapper;

    // 1. 카테고리 목록 조회 (게시글 작성 필터용)
    @GetMapping("/categories")
    public ResponseEntity<ApiResponse<List<Category>>> getCategories() {
        return ResponseEntity.ok(ApiResponse.success("카테고리 목록 조회 성공", categoryMapper.findAll()));
    }

    // 2. 회사 목록 부분 조회 (회원가입 드롭다운 등)
    @GetMapping("/companies")
    public ResponseEntity<ApiResponse<List<Company>>> getCompanies() {
        return ResponseEntity.ok(ApiResponse.success("회사 목록 조회 성공", companyMapper.findAll()));
    }

    // 3. 관리자의 고객사/협력사 추가 기능
    @PostMapping("/companies")
    public ResponseEntity<ApiResponse<Void>> addCompany(@RequestBody Company company, HttpServletRequest request) {
        User loginUser = (User) request.getSession(false).getAttribute("LOGIN_USER");
        if (loginUser.getRole() != 1) { // 1번 슈퍼관리자만 추가 가능
            return ResponseEntity.status(403).body(ApiResponse.error("회사 등록은 관리자만 가능합니다."));
        }
        
        companyMapper.save(company);
        return ResponseEntity.ok(ApiResponse.success("회사가 성공적으로 등록되었습니다."));
    }

    // 4. 관리자의 고객사/협력사 수정 기능
    @PutMapping("/companies/{companyId}")
    public ResponseEntity<ApiResponse<Void>> updateCompany(
            @PathVariable("companyId") Long companyId, 
            @RequestBody Company company, 
            HttpServletRequest request) {
        
        User loginUser = (User) request.getSession(false).getAttribute("LOGIN_USER");
        if (loginUser.getRole() != 1) {
            return ResponseEntity.status(403).body(ApiResponse.error("회사 수정은 관리자만 가능합니다."));
        }
        
        company.setCompanyId(companyId);
        companyMapper.update(company);
        return ResponseEntity.ok(ApiResponse.success("회사 정보가 성공적으로 수정되었습니다."));
    }

    // 5. 관리자의 고객사/협력사 삭제 기능
    @DeleteMapping("/companies/{companyId}")
    public ResponseEntity<ApiResponse<Void>> deleteCompany(
            @PathVariable("companyId") Long companyId, 
            HttpServletRequest request) {
        
        User loginUser = (User) request.getSession(false).getAttribute("LOGIN_USER");
        if (loginUser.getRole() != 1) {
            return ResponseEntity.status(403).body(ApiResponse.error("회사 삭제는 관리자만 가능합니다."));
        }

        try {
            companyMapper.deleteById(companyId);
            return ResponseEntity.ok(ApiResponse.success("회사가 성공적으로 삭제되었습니다."));
        } catch (Exception e) {
            // 소속된 회원이 존재하면 DB 외래키 제약조건에 의해 에러가 터짐
            return ResponseEntity.status(400).body(ApiResponse.error("해당 소속으로 등록된 회원이 존재하여 삭제할 수 없습니다."));
        }
    }
}
