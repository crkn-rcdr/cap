UPDATE info SET value = '61' WHERE name = 'version';

ALTER TABLE subscription DROP COLUMN rcpt_amt, DROP COLUMN rcpt_name, DROP COLUMN rcpt_address, DROP COLUMN rcpt_no, DROP COLUMN rcpt_id, DROP COLUMN rcpt_date;
ALTER TABLE subscription ADD COLUMN portal_id VARCHAR(64) AFTER user_id;
UPDATE subscription SET portal_id = 'eco';
ALTER TABLE subscription MODIFY COLUMN portal_id VARCHAR(64) NOT NULL;
ALTER TABLE subscription ADD CONSTRAINT subscription_ibfk_3 FOREIGN KEY(portal_id) REFERENCES portal(id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE subscription CHANGE promo discount_code VARCHAR(16);
ALTER TABLE subscription ADD discount_amount DECIMAL(10,2) AFTER discount_code;
