CREATE DATABASE IF NOT EXISTS nacos_evoting CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nacos_evoting;
CREATE TABLE IF NOT EXISTS users (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, full_name VARCHAR(140) NOT NULL, email VARCHAR(190) NOT NULL UNIQUE,
 matric_no VARCHAR(60) UNIQUE NULL, password_hash VARCHAR(255) NOT NULL, role ENUM('admin','officer','student') NOT NULL DEFAULT 'student',
 department VARCHAR(120) NULL, level VARCHAR(30) NULL, is_verified TINYINT(1) NOT NULL DEFAULT 0,
 is_active TINYINT(1) NOT NULL DEFAULT 1, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS elections (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, title VARCHAR(180) NOT NULL, description TEXT NULL,
 starts_at DATETIME NOT NULL, ends_at DATETIME NOT NULL, status ENUM('draft','scheduled','open','closed') NOT NULL DEFAULT 'draft',
 created_by BIGINT UNSIGNED NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_election_creator FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS positions (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, election_id BIGINT UNSIGNED NOT NULL, title VARCHAR(120) NOT NULL,
 description TEXT NULL, max_votes TINYINT UNSIGNED NOT NULL DEFAULT 1, sort_order INT NOT NULL DEFAULT 0,
 CONSTRAINT fk_position_election FOREIGN KEY(election_id) REFERENCES elections(id) ON DELETE CASCADE
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS candidates (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, position_id BIGINT UNSIGNED NOT NULL, full_name VARCHAR(140) NOT NULL,
 department VARCHAR(120) NULL, manifesto TEXT NULL, photo VARCHAR(255) NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 application_user_id BIGINT UNSIGNED NULL, approval_status ENUM('pending','approved','declined') NOT NULL DEFAULT 'approved',
 reviewed_by BIGINT UNSIGNED NULL, reviewed_at DATETIME NULL, review_note VARCHAR(500) NULL,
 INDEX idx_candidate_review(position_id,approval_status), INDEX idx_candidate_applicant(application_user_id),
 CONSTRAINT fk_candidate_applicant FOREIGN KEY(application_user_id) REFERENCES users(id) ON DELETE SET NULL,
 CONSTRAINT fk_candidate_reviewer FOREIGN KEY(reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
 CONSTRAINT fk_candidate_position FOREIGN KEY(position_id) REFERENCES positions(id) ON DELETE CASCADE
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS votes (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, election_id BIGINT UNSIGNED NOT NULL, position_id BIGINT UNSIGNED NOT NULL,
 candidate_id BIGINT UNSIGNED NOT NULL, voter_id BIGINT UNSIGNED NOT NULL, cast_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 UNIQUE KEY uq_voter_position (voter_id, position_id), INDEX idx_vote_results(position_id,candidate_id),
 CONSTRAINT fk_vote_election FOREIGN KEY(election_id) REFERENCES elections(id) ON DELETE CASCADE,
 CONSTRAINT fk_vote_position FOREIGN KEY(position_id) REFERENCES positions(id) ON DELETE CASCADE,
 CONSTRAINT fk_vote_candidate FOREIGN KEY(candidate_id) REFERENCES candidates(id) ON DELETE CASCADE,
 CONSTRAINT fk_vote_voter FOREIGN KEY(voter_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS audit_logs (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id BIGINT UNSIGNED NULL, action VARCHAR(120) NOT NULL,
 details TEXT NULL, ip_address VARCHAR(45) NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 INDEX idx_audit_created(created_at), CONSTRAINT fk_audit_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;
