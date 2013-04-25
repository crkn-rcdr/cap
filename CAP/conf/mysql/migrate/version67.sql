UPDATE info SET value = '67' WHERE name = 'version';

ALTER TABLE portal ADD COLUMN access_search BOOLEAN NOT NULL DEFAULT 0 AFTER access_purchase;
ALTER TABLE portal ADD COLUMN access_browse BOOLEAN NOT NULL DEFAULT 0 AFTER access_search;
