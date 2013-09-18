UPDATE info SET value = '63' WHERE name = 'version';

ALTER TABLE subscription ADD COLUMN old_level INT AFTER newexpire, ADD COLUMN new_level INT AFTER old_level;
ALTER TABLE subscription ADD COLUMN product VARCHAR(32) AFTER success;
ALTER TABLE subscription CHANGE COLUMN oldexpire old_expire DATETIME;
ALTER TABLE subscription CHANGE COLUMN newexpire new_expire DATETIME;
