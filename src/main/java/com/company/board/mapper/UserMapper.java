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
}
