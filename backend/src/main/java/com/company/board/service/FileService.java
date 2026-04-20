package com.company.board.service;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.UUID;

@Service
public class FileService {

    // 로컬 저장소 경로 /uploads
    private final String UPLOAD_DIR = System.getProperty("user.dir") + "/uploads/";

    // 1. 파일 저장 메인 로직
    public String saveFile(MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            return null;
        }

        // 폴더가 없으면 생성
        File directory = new File(UPLOAD_DIR);
        if (!directory.exists()) {
            directory.mkdirs();
        }

        // 원본 파일명 (예: 테스트.png)
        String originalFilename = file.getOriginalFilename();

        // 확장자 추출 (예: .png)
        String extension = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        }

        // 랜덤 파일명 생성 (예: 550e8400-e29b-41d4-a716-446655440000.png)
        String savedFilename = UUID.randomUUID().toString() + extension;

        // 지정된 폴더에 파일 복사(저장)
        File dest = new File(UPLOAD_DIR + savedFilename);
        file.transferTo(dest);

        return savedFilename;
    }

    public org.springframework.core.io.Resource loadFileAsResource(String fileName) {
        try {
            java.nio.file.Path filePath = java.nio.file.Paths.get(UPLOAD_DIR).resolve(fileName).normalize();
            org.springframework.core.io.Resource resource = new org.springframework.core.io.UrlResource(filePath.toUri());
            if (resource.exists()) {
                return resource;
            } else {
                return null;
            }
        } catch (java.net.MalformedURLException ex) {
            return null;
        }
    }
}
