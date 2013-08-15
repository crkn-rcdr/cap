-- CAP Database version 74:
-- Add fields to the pages table to record transcriptions and the
-- transcription status

ALTER TABLE pages
    ADD COLUMN transcription_status ENUM('not_transcribed', 'locked_for_transcription', 'awaiting_review',
    'locked_for_review', 'transcribed', 'transcribed_with_corrections') DEFAULT 'not_transcribed' AFTER label,
    ADD INDEX(transcription_status),
    ADD COLUMN transcription_user_id INT AFTER label,
    ADD FOREIGN KEY(transcription_user_id) REFERENCES user(id) ON DELETE SET NULL ON UPDATE CASCADE,
    ADD COLUMN review_user_id INT AFTER transcription_user_id,
    ADD FOREIGN KEY(review_user_id) REFERENCES user(id) ON UPDATE CASCADE ON DELETE SET NULL,
    ADD COLUMN transcription TEXT AFTER transcription_status,
    ADD COLUMN type ENUM('unknown', 'control', 'single_page', 'start_page', 'end_page', 'middle_page') DEFAULT 'unknown' AFTER transcription,
    ADD COLUMN updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
UPDATE pages SET transcription_status = 'not_transcribed', type = 'unknown';
ALTER TABLE pages
    CHANGE COLUMN transcription_status transcription_status ENUM('not_transcribed', 'locked_for_transcription',
    'awaiting_review', 'locked_for_review', 'transcribed', 'transcribed_with_corrections') DEFAULT 'not_transcribed' NOT NULL,
    CHANGE COLUMN type type ENUM('unknown', 'control', 'single_page', 'start_page', 'end_page', 'middle_page') DEFAULT 'unknown' NOT NULL,
    CHANGE COLUMN updated updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL;

-- Set the new table version
UPDATE info SET value = '74' WHERE name = 'version';
