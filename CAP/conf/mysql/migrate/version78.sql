-- CAP Database version 78:
-- Add the reviewer role to the roles table; add the public_contributions flag

INSERT INTO cap_core.roles SET id = 'reviewer', description = 'perform quality control review';
ALTER TABLE user ADD COLUMN public_contributions BOOLEAN DEFAULT FALSE AFTER can_review;

-- Set the new table version
UPDATE info SET value = '78' WHERE name = 'version';
