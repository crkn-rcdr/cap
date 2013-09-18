UPDATE info SET value = '65' WHERE name = 'version';

ALTER TABLE portal_host ADD COLUMN canonical BOOLEAN AFTER portal_id;
ALTER TABLE portal_host ADD CONSTRAINT UNIQUE INDEX canonical_host (id, canonical);
UPDATE portal_host SET canonical = TRUE where id != 'recherche';
