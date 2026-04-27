package com.company.board.mapper;

import com.company.board.domain.User;
import org.apache.ibatis.annotations.Mapper;
import java.util.List;

@Mapper // MyBatis를 이용하는 DB 연결 인터페이스
public interface UserMapper {
    // 1. 회원가입
    void save(User user);

    // 2. 로그인 ID로 단일 유저 조회
    User findByLoginId(String loginId);

    // 3. User 고유번호(PK)로 단일 유저 찾기
    User findById(Long userId);
 
    // 4. 모든 유저 목록 조회
    List<User> findAll();

    // 5. 유저 권한 수정 (관리자 전용)
    void updateRole(@org.apache.ibatis.annotations.Param("userId") Long userId, @org.apache.ibatis.annotations.Param("role") Integer role);

    // 6. 담당자 후보 목록 조회 (본사 소속)
    List<User> findStaffUsers();

    // 7. 조회: 가입 승인 대기 목록 (status=0)
    List<User> findPendingUsers();

    // 8. 대상 유저 상태 업데이트 (승인/거절)
    void updateStatus(@org.apache.ibatis.annotations.Param("userId") Long userId, @org.apache.ibatis.annotations.Param("status") Integer status);

    // 9. 회원 정보 수정 (회사, 상태 등)
    void update(User user);

    // 10. 회원 삭제
    void deleteById(Long userId);
}
