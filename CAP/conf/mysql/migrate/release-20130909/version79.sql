-- CAP Database version 79:
-- Fix portal_lang to add a trigger that deletes rows when the parent
-- portal is deleted.

ALTER TABLE portal_lang DROP FOREIGN KEY portal_lang_ibfk_1;
ALTER TABLE portal_lang ADD FOREIGN KEY(portal_id) REFERENCES portal(id) ON DELETE CASCADE ON UPDATE CASCADE;

-- Set the new table version
UPDATE info SET value = '79' WHERE name = 'version';
