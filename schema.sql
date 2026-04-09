-- 1. 데이터베이스 생성 (문자 깨짐 방지를 위해 utf8mb4 사용)
CREATE DATABASE IF NOT EXISTS board_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE board_db;

-- 1.5 회사(소속) 테이블 (본사, 고객사, 협력사)
CREATE TABLE IF NOT EXISTS `company` (
    `company_id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `company_name` VARCHAR(100) NOT NULL UNIQUE,
    `company_type` TINYINT NOT NULL COMMENT '1:본사, 2:고객사, 3:협력사',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 초기 기초 회사 세팅 (본사)
INSERT INTO company (company_name, company_type) VALUES ('(주)보드본사', 1) 
ON DUPLICATE KEY UPDATE company_type=VALUES(company_type);

-- 2. 유저 테이블
CREATE TABLE IF NOT EXISTS `user` (
    `user_id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `login_id` VARCHAR(50) NOT NULL UNIQUE,
    `password` VARCHAR(255) NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `company_id` BIGINT NOT NULL,
    `role` TINYINT NOT NULL COMMENT '1:슈퍼관리자, 2:일반회원',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`company_id`) REFERENCES `company`(`company_id`)
);

-- 3. 게시글 상태 테이블
CREATE TABLE IF NOT EXISTS `post_status` (
    `status_id` INT AUTO_INCREMENT PRIMARY KEY,
    `status_name` VARCHAR(50) NOT NULL
);

INSERT INTO post_status (status_name) VALUES ('진행중'), ('완료'), ('미해결'), ('숨김') 
ON DUPLICATE KEY UPDATE status_name=VALUES(status_name);

-- 3.5 카테고리 테이블 (버그, 오류, 문의 등)
CREATE TABLE IF NOT EXISTS `post_category` (
    `category_id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `category_name` VARCHAR(50) NOT NULL
);

INSERT INTO post_category (category_name) VALUES ('버그/오류'), ('기능문의'), ('계정/권한'), ('기타')
ON DUPLICATE KEY UPDATE category_name=VALUES(category_name);

-- 4. 게시글 테이블
CREATE TABLE IF NOT EXISTS `post` (
    `post_id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT NOT NULL,
    `status_id` INT NOT NULL,
    `category_id` BIGINT NOT NULL,
    `priority` TINYINT DEFAULT 2 COMMENT '1:낮음, 2:보통, 3:높음, 4:긴급',
    `assigned_user_id` BIGINT DEFAULT NULL COMMENT '담당 처리자(본사직원 등)',
    `title` VARCHAR(255) NOT NULL,
    `content` TEXT NOT NULL,
    `view_count` INT DEFAULT 0,
    `is_deleted` BOOLEAN DEFAULT FALSE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `user`(`user_id`),
    FOREIGN KEY (`assigned_user_id`) REFERENCES `user`(`user_id`),
    FOREIGN KEY (`status_id`) REFERENCES `post_status`(`status_id`),
    FOREIGN KEY (`category_id`) REFERENCES `post_category`(`category_id`)
);

-- 5. 댓글 테이블
CREATE TABLE IF NOT EXISTS `comment` (
    `comment_id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `post_id` BIGINT NOT NULL,
    `user_id` BIGINT NOT NULL,
    `parent_id` BIGINT DEFAULT NULL,
    `content` VARCHAR(1000) NOT NULL,
    `is_deleted` BOOLEAN DEFAULT FALSE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`post_id`) REFERENCES `post`(`post_id`),
    FOREIGN KEY (`user_id`) REFERENCES `user`(`user_id`),
    FOREIGN KEY (`parent_id`) REFERENCES `comment`(`comment_id`)
);

-- 6. 첨부 파일 테이블
CREATE TABLE IF NOT EXISTS `file` (
    `file_id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `post_id` BIGINT NOT NULL,
    `original_name` VARCHAR(255) NOT NULL,
    `saved_name` VARCHAR(255) NOT NULL,
    `file_path` VARCHAR(255) NOT NULL,
    `file_size` BIGINT NOT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`post_id`) REFERENCES `post`(`post_id`)
);

-- 7. 공지사항 전용 테이블
CREATE TABLE IF NOT EXISTS `notice` (
    `notice_id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `content` TEXT NOT NULL,
    `view_count` INT DEFAULT 0,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `user`(`user_id`)
);
