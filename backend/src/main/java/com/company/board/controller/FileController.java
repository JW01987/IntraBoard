package com.company.board.controller;

import com.company.board.common.ApiResponse;
import com.company.board.domain.PostFile;
import com.company.board.service.FileService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/files")
@RequiredArgsConstructor
public class FileController {

    private final FileService fileService;

    // 파일만 먼저 처리
    @PostMapping("/upload")
    public ResponseEntity<ApiResponse<List<PostFile>>> uploadFiles(@RequestParam("files") List<MultipartFile> files) {
        List<PostFile> resultList = new ArrayList<>();

        for (MultipartFile file : files) {
            try {
                // 1. 서버 저장 후 UUID 받기
                String savedName = fileService.saveFile(file);
                
                // 2. 저장 후 원본 이름 저장, 사이즈, UUID DB저장
                if (savedName != null) {
                    PostFile postFile = new PostFile();
                    postFile.setOriginalName(file.getOriginalFilename());
                    postFile.setSavedName(savedName);
                    postFile.setFileSize(file.getSize());
                    
                    resultList.add(postFile);
                }
            } catch (IOException e) {
                return ResponseEntity.status(500).body(ApiResponse.error("파일 저장 중 오류가 발생했습니다."));
            }
        }
        
        return ResponseEntity.ok(ApiResponse.success("파일 업로드 성공", resultList));
    }
}
