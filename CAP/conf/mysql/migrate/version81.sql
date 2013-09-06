-- CAP Database version 81:
-- Fix incorrect foreign key dependency in users_discounts


ALTER TABLE users_discounts DROP FOREIGN KEY users_discounts_ibfk_1;
ALTER TABLE users_discounts ADD CONSTRAINT users_discounts_ibfk_1 FOREIGN KEY(user_id) REFERENCES user(id) ON DELETE CASCADE ON UPDATE CASCADE;


-- Set the new table version
UPDATE info SET value = '81' WHERE name = 'version';

