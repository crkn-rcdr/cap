-- UPDATE info SET value = '60' WHERE name = 'version';
-- 
-- ALTER TABLE titles ADD COLUMN updated TIMESTAMP AFTER label;
-- ALTER TABLE titles ADD INDEX(updated);
-- ALTER TABLE portals_titles ADD COLUMN updated TIMESTAMP AFTER hosted;
-- ALTER TABLE portals_titles ADD INDEX(updated);
-- ALTER TABLE info ADD COLUMN time DATETIME AFTER value;

-- DROP TABLE portal_subscription;
-- CREATE TABLE portal_subscriptions(id VARCHAR(32) PRIMARY KEY, portal_id VARCHAR(64), FOREIGN KEY(portal_id) REFERENCES portal(id), level INT, duration INT, price DECIMAL(10,2)) ENGINE=INNODB DEFAULT CHARSET=utf8;


ALTER TABLE portal DROP COLUMN view_all, DROP COLUMN view_limited, DROP COLUMN resize, DROP COLUMN download;
ALTER TABLE portal ADD COLUMN users BOOLEAN NOT NULL DEFAULT FALSE, ADD COLUMN subscriptions BOOLEAN NOT NULL DEFAULT FALSE, ADD COLUMN institutions BOOLEAN NOT NULL DEFAULT FALSE, ADD COLUMN access_preview INT NOT NULL DEFAULT 0, ADD COLUMN access_all INT NOT NULL DEFAULT 0, ADD COLUMN access_resize INT NOT NULL DEFAULT 0, ADD COLUMN access_download INT NOT NULL DEFAULT 0, ADD COLUMN access_purchase INT NOT NULL DEFAULT 0, ADD COLUMN updated TIMESTAMP;

ALTER TABLE portal_lang ADD COLUMN title VARCHAR(128) DEFAULT 'NEW PORTAL';

UPDATE portal_lang SET title = 'The War of 1812' WHERE portal_id = '1812' AND lang = 'en';
UPDATE portal_lang SET title = 'La guerre de 1812' WHERE portal_id = '1812' AND lang = 'fr';
UPDATE portal_lang SET title = 'Canadian Agriculture Library' WHERE portal_id = 'agriculture' AND lang = 'en';
UPDATE portal_lang SET title = 'Bibliothèque canadienne de l\'agriculture' WHERE portal_id = 'agriculture' AND lang = 'fr';
UPDATE portal_lang SET title = 'Canadiana Discovery Portal' WHERE portal_id = 'co' AND lang = 'en';
UPDATE portal_lang SET title = 'Portail de recherche de Canadiana' WHERE portal_id = 'co' AND lang = 'fr';
UPDATE portal_lang SET title = 'DFAIT Digital Library' WHERE portal_id = 'dfait' AND lang = 'en';
UPDATE portal_lang SET title = 'Bibliothèque numérique du MAECI' WHERE portal_id = 'dfait' AND lang = 'fr';
UPDATE portal_lang SET title = 'Early Canadiana Online' WHERE portal_id = 'eco' AND lang = 'en';
UPDATE portal_lang SET title = 'Notre mémoire en ligne' WHERE portal_id = 'eco' AND lang = 'fr';
UPDATE portal_lang SET title = 'Historical Debates of the Parliament of Canada' WHERE portal_id = 'parl' AND lang = 'en';
UPDATE portal_lang SET title = 'Débats historiques du Parlement du Canada' WHERE portal_id = 'parl' AND lang = 'fr';
UPDATE portal_lang SET title = 'Women\'s History' WHERE portal_id = 'whf' AND lang = 'en';
UPDATE portal_lang SET title = 'Histoire des femmes' WHERE portal_id = 'whf' AND lang = 'fr';

DROP TABLE IF EXISTS portal_string;
DROP TABLE IF EXISTS portal_support;
