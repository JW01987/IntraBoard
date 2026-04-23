package com.company.board.service;

import com.company.board.domain.User;
import com.company.board.mapper.UserMapper;
import com.company.board.util.PasswordUtils;
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
        // 비밀번호를 일방향 암호화(SHA-256)해서 저장
        String encryptedPassword = PasswordUtils.encrypt(user.getPassword());
        user.setPassword(encryptedPassword);
        
        // 권한(role)이 제공되지 않은 경우 기본값 '일반회원(2)'으로 설정
        // TODO: 추후 수정 (프로필에서 관리자 권한 신청....)
        if (user.getRole() == null) {
            user.setRole(com.company.board.constant.UserRole.MEMBER.getCode());
        }
        
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

        // 만약 유저가 존재하고 && 사용자가 입력한 비밀번호(암호화 검증)가 맞다면?
        if (user != null && PasswordUtils.match(password, user.getPassword())) {
            return user; // 로그인된 유저 객체 반환
        }
        
        // 아이디가 없거나 비밀번호가 틀리면 실패
        return null;
    }

    // 4. 유저 권한 변경 로직 (관리자 전용)
    public void updateUserRole(Long userId, Integer role) {
        userMapper.updateRole(userId, role);
    }

    // 5. 담당자 후보 목록 조회 (본사 직원)
    public java.util.List<User> getStaffList() {
        return userMapper.findStaffUsers();
    }

    // 6. 승인 대기 목록 조회
    public java.util.List<User> getPendingUsers() {
        return userMapper.findPendingUsers();
    }

    // 7. 전체 목록 조회
    public java.util.List<User> getAllUsers() {
        return userMapper.findAll();
    }

    // 8. 회원 승인 상태 업데이트
    public void updateUserStatus(Long userId, Integer status) {
        userMapper.updateStatus(userId, status);
    }
}
