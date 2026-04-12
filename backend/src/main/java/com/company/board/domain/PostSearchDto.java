package com.company.board.domain;

import lombok.Getter;
import lombok.Setter;
import java.time.LocalDate;

@Getter
@Setter
public class PostSearchDto {
    private String keyword;
    private String boardType; // NOTICE(공지), ISSUE(이슈/문의), ARCHIVE(자료실)
    private Integer statusId; // 1. 진행중 2.완료 3.미해결 4. 숨김
    private Long categoryId; // 구분 검색
    private Integer priority; // 중요도 검색
    private Long companyId; // 고객사별 분류 필터
    private Long assignedUserId; // 내게 할당된 작업 검색
    
    private LocalDate startDate;
    private LocalDate endDate;
    private String authorName; // 작성자 검색

    // --- 페이징(Paging) 전용 변수 ---
    private int page = 1; // 기본 페이지: 1쪽부터
    private int size = 10; // 한 페이지당 10개씩 //TODO: 추후 수정 가능하게

    // OFFSET(어디서부터 자를지) 자동 계산기
    // 예: 2페이지면 (2-1)*10 = 10 (앞에 10개 버리고 11번째부터 가져와!)
    public int getOffset() {
        return (page - 1) * size;
    }
}
