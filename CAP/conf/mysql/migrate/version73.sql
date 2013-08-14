-- CAP Database version 73:
-- Add the supports transcription flag to the portal table.

ALTER TABLE portal ADD COLUMN supports_transcriptions BOOLEAN DEFAULT FALSE AFTER supports_institutions;
UPDATE portal SET supports_transcriptions = FALSE;
ALTER TABLE portal CHANGE supports_transcriptions supports_transcriptions BOOLEAN DEFAULT FALSE NOT NULL;

-- Set the new table version
UPDATE info SET value = '73' WHERE name = 'version';
