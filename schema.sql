-- 1. 데이터베이스 생성 (문자 깨짐 방지를 위해 utf8mb4 사용)
CREATE DATABASE IF NOT EXISTS board_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE board_db;

-- 2. 유저 테이블
CREATE TABLE IF NOT EXISTS `user` (
    `user_id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `login_id` VARCHAR(50) NOT NULL UNIQUE,
    `password` VARCHAR(255) NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `company_name` VARCHAR(100) NOT NULL,
    `role` TINYINT NOT NULL COMMENT '1:관리자, 2:본사, 3:고객사, 4:협력사',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 3. 게시글 상태 테이블
CREATE TABLE IF NOT EXISTS `post_status` (
    `status_id` INT AUTO_INCREMENT PRIMARY KEY,
    `status_name` VARCHAR(50) NOT NULL
);

INSERT INTO post_status (status_name) VALUES ('진행중'), ('완료'), ('미해결'), ('숨김') 
ON DUPLICATE KEY UPDATE status_name=VALUES(status_name);

-- 4. 게시글 테이블
CREATE TABLE IF NOT EXISTS `post` (
    `post_id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT NOT NULL,
    `status_id` INT NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `content` TEXT NOT NULL,
    `view_count` INT DEFAULT 0,
    `is_deleted` BOOLEAN DEFAULT FALSE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `user`(`user_id`),
    FOREIGN KEY (`status_id`) REFERENCES `post_status`(`status_id`)
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
