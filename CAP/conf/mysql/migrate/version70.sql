-- CAP Database version 70:
-- Alter the user table to change the existing username field to an email
-- address field and add a new username field. Also modify the login,
-- created and updated fields. A default username is the combination of
-- the name part of the user's email and the user id.

ALTER TABLE user CHANGE username email VARCHAR(128) UNIQUE;
ALTER TABLE user ADD COLUMN username VARCHAR(64) UNIQUE AFTER id;
ALTER TABLE user CHANGE created created DATETIME NOT NULL;
ALTER TABLE user ADD COLUMN last_login DATETIME AFTER lastseen;
ALTER TABLE user DROP COLUMN lastseen;
ALTER TABLE user ADD COLUMN updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
UPDATE user SET username = CONCAT(LEFT(email, INSTR(email, '@') - 1), id);
ALTER TABLE user CHANGE username username VARCHAR(64) NOT NULL UNIQUE;
ALTER TABLE user CHANGE updated updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE user ADD INDEX updated(updated);

-- Set the new table version
UPDATE info SET value = '70' WHERE name = 'version';
