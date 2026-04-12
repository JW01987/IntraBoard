package com.company.board.service;

import com.company.board.domain.Notice;
import com.company.board.mapper.NoticeMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class NoticeService {

    private final NoticeMapper noticeMapper;

    // 1. 공지사항 저장 
    public void createNotice(Notice notice) {
        noticeMapper.save(notice);
    }

    // 2. 공지사항 목록 조회
    public List<Notice> getNoticeList() {
        return noticeMapper.findAll();
    }

    // 3. 공지사항 상세 조회
    public Notice getNoticeDetail(Long noticeId) {
        noticeMapper.increaseViewCount(noticeId);
        return noticeMapper.findById(noticeId);
    }

    // 4. 공지사항 단건 조회
    public Notice getNoticeBasic(Long noticeId) {
        return noticeMapper.findById(noticeId);
    }

    // 5. 공지사항 수정
    public void updateNotice(Notice notice) {
        noticeMapper.update(notice);
    }

    // 6. 공지사항 삭제
    public void deleteNotice(Long noticeId) {
        noticeMapper.deleteById(noticeId);
    }
}
