-- CAP Database version 72:
-- Add access level and transcribable columns to the titles table

ALTER TABLE titles ADD COLUMN level INT DEFAULT 0 AFTER label, ADD COLUMN transcribable BOOLEAN DEFAULT FALSE AFTER level;
UPDATE titles SET level = 2, transcribable = FALSE;
ALTER TABLE titles CHANGE COLUMN level level INT DEFAULT 0 NOT NULL, CHANGE COLUMN transcribable transcribable BOOLEAN DEFAULT FALSE NOT NULL;

-- Set the new table version
UPDATE info SET value = '72' WHERE name = 'version';
