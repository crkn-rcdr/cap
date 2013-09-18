UPDATE info SET value = '66' WHERE name = 'version';

ALTER TABLE user_log DROP FOREIGN KEY `user_log_ibfk_1`;
ALTER TABLE user_log ADD CONSTRAINT `user_log_ibfk_1` FOREIGN KEY(user_id) REFERENCES user(id) ON DELETE CASCADE ON UPDATE CASCADE;
RENAME TABLE cap.user_log TO cap_log.user_log;
