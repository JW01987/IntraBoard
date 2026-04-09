package com.company.board.mapper;

import com.company.board.domain.Company;
import org.apache.ibatis.annotations.Mapper;
import java.util.List;

@Mapper
public interface CompanyMapper {
    // 1. 회사 추가
    void save(Company company);
    // 2. 회사 전체 조회
    List<Company> findAll();
    // 3. 회사 수정
    void update(Company company);
    // 4. 회사 삭제
    void deleteById(Long companyId);
}
