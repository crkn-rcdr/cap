-- CAP Database version 71:
-- Add user transcription flags to indicate whether users are or aren't
-- allowed to submit and/or review transcriptions

ALTER TABLE user ADD COLUMN can_transcribe BOOLEAN DEFAULT TRUE AFTER credits;
ALTER TABLE user ADD COLUMN can_review BOOLEAN DEFAULT TRUE AFTER can_transcribe;
UPDATE user SET can_transcribe = TRUE, can_review = TRUE;

-- Set the new table version
UPDATE info SET value = '71' WHERE name = 'version';
