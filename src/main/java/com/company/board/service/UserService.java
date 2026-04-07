package com.company.board.service;

import com.company.board.domain.User;
import com.company.board.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service //비즈니스 로직 서비스
@RequiredArgsConstructor // final이 붙은 변수를 알아서 연결(의존성 주입)
public class UserService {

    // 매퍼(인터페이스)를 가져와 사용
    // NestJS의 DI(Dependency Injection, 의존성 주입)와 같음
    private final UserMapper userMapper;

    // 1. 회원가입 로직
    public void registerUser(User user) {
        // TODO: 암호화
        userMapper.save(user);
    }

    // 2. 단일 회원 조회 로직
    public User getUserById(Long userId) {
        return userMapper.findById(userId);
    }

    // 3. 로그인 검증 로직
    public User login(String loginId, String password) {
        // 아이디로 DB에서 유저를 찾음
        User user = userMapper.findByLoginId(loginId);

        // 만약 유저가 존재하고 && 사용자가 입력한 비밀번호와 DB 비밀번호가 같다면?
        if (user != null && user.getPassword().equals(password)) {
            return user; // 로그인된 유저 객체 반환
        }
        
        // 아이디가 없거나 비밀번호가 틀리면 실패
        return null;
    }
}
