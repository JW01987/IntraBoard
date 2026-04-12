package com.company.board.mapper;

import com.company.board.domain.Notice;
import org.apache.ibatis.annotations.Mapper;
import java.util.List;

@Mapper
public interface NoticeMapper {
    // 1. 공지사항 저장
    void save(Notice notice);

    // 2. 공지사항 단건 조회
    Notice findById(Long noticeId);

    // 3. 공지사항 목록 조회
    List<Notice> findAll();

    // 4. 공지사항 수정
    void update(Notice notice);

    // 5. 공지사항 삭제
    void deleteById(Long noticeId);

    // 6. 공지사항 조회수 증가
    void increaseViewCount(Long noticeId);
}
