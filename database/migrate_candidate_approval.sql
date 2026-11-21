-- Run once on an existing installation using phpMyAdmin or the MySQL client.
-- Adds candidate-review metadata only; existing accounts and credentials are untouched.
ALTER TABLE candidates
    ADD COLUMN application_user_id BIGINT UNSIGNED NULL AFTER created_at,
    ADD COLUMN approval_status ENUM('pending','approved','declined') NOT NULL DEFAULT 'approved' AFTER application_user_id,
    ADD COLUMN reviewed_by BIGINT UNSIGNED NULL AFTER approval_status,
    ADD COLUMN reviewed_at DATETIME NULL AFTER reviewed_by,
    ADD COLUMN review_note VARCHAR(500) NULL AFTER reviewed_at,
    ADD INDEX idx_candidate_review(position_id, approval_status),
    ADD INDEX idx_candidate_applicant(application_user_id),
    ADD CONSTRAINT fk_candidate_applicant FOREIGN KEY(application_user_id) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_candidate_reviewer FOREIGN KEY(reviewed_by) REFERENCES users(id) ON DELETE SET NULL;
