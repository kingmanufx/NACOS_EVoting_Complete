-- Run once on an existing installation that already uses database/schema.sql.
-- Back up the database first. Historic linked vote rows are aggregated and then dropped.
ALTER TABLE users ADD COLUMN email_verified_at DATETIME NULL;
UPDATE users SET email_verified_at = NOW() WHERE email_verified_at IS NULL;

CREATE TABLE IF NOT EXISTS account_tokens (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id BIGINT UNSIGNED NOT NULL,
 purpose ENUM('verify_email','reset_password') NOT NULL, token_hash CHAR(64) NOT NULL UNIQUE,
 expires_at DATETIME NOT NULL, used_at DATETIME NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 INDEX idx_account_token_user(user_id,purpose,created_at),
 CONSTRAINT fk_account_token_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS voter_participation (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, election_id BIGINT UNSIGNED NOT NULL, voter_id BIGINT UNSIGNED NOT NULL,
 cast_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, UNIQUE KEY uq_voter_election(election_id,voter_id),
 CONSTRAINT fk_participation_election FOREIGN KEY(election_id) REFERENCES elections(id) ON DELETE CASCADE,
 CONSTRAINT fk_participation_voter FOREIGN KEY(voter_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

INSERT IGNORE INTO voter_participation(election_id,voter_id,cast_at)
SELECT election_id,voter_id,MIN(cast_at) FROM votes GROUP BY election_id,voter_id;

CREATE TABLE votes_aggregate (
 election_id BIGINT UNSIGNED NOT NULL, position_id BIGINT UNSIGNED NOT NULL, candidate_id BIGINT UNSIGNED NOT NULL,
 vote_count BIGINT UNSIGNED NOT NULL DEFAULT 0, PRIMARY KEY(election_id,position_id,candidate_id),
 INDEX idx_vote_results(position_id,candidate_id)
) ENGINE=InnoDB;
INSERT INTO votes_aggregate(election_id,position_id,candidate_id,vote_count)
SELECT election_id,position_id,candidate_id,COUNT(*) FROM votes GROUP BY election_id,position_id,candidate_id;

RENAME TABLE votes TO votes_linked_archive, votes_aggregate TO votes;
DROP TABLE votes_linked_archive;

ALTER TABLE votes
 ADD CONSTRAINT fk_vote_election FOREIGN KEY(election_id) REFERENCES elections(id) ON DELETE CASCADE,
 ADD CONSTRAINT fk_vote_position FOREIGN KEY(position_id) REFERENCES positions(id) ON DELETE CASCADE,
 ADD CONSTRAINT fk_vote_candidate FOREIGN KEY(candidate_id) REFERENCES candidates(id) ON DELETE CASCADE;
