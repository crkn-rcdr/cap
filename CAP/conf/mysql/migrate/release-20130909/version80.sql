-- CAP Database version 80:
-- Add a title_views log.

CREATE TABLE cap_log.title_views(
    id INT AUTO_INCREMENT PRIMARY KEY,
    title_id INT, INDEX(title_id),
    user_id INT, INDEX(user_id),
    institution_id INT, INDEX(institution_id),
    portal_id VARCHAR(64), INDEX(portal_id),
    time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX(time),
    session VARCHAR(40), INDEX(session)
) ENGINE=INNODB DEFAULT CHARSET=utf8;


-- Set the new table version
UPDATE info SET value = '80' WHERE name = 'version';
