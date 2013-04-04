UPDATE info SET value = '59' WHERE name = 'version';

DROP TABLE IF EXISTS document_collection;
DROP TABLE IF EXISTS portal_collection;
DROP TABLE IF EXISTS collection;
DROP TABLE IF EXISTS cap_log.cron;
ALTER TABLE user DROP COLUMN class, DROP COLUMN subexpires, DROP COLUMN remindersent;

RENAME TABLE cap.request_log TO cap_log.requests;
