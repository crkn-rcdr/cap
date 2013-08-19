-- CAP Database version 76:
-- Remove the now unneeded access_ fields from cap.portal

ALTER TABLE portal DROP COLUMN access_preview;
ALTER TABLE portal DROP COLUMN access_all;
ALTER TABLE portal DROP COLUMN access_resize;
ALTER TABLE portal DROP COLUMN access_download;
ALTER TABLE portal DROP COLUMN access_purchase;
ALTER TABLE portal DROP COLUMN access_search;
ALTER TABLE portal DROP COLUMN access_browse;

-- Set the new table version
UPDATE info SET value = '76' WHERE name = 'version';
