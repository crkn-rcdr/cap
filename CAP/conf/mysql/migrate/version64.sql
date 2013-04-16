UPDATE info SET value = '64' WHERE name = 'version';

ALTER TABLE portal CHANGE users supports_users BOOLEAN NOT NULL DEFAULT 0;
ALTER TABLE portal CHANGE subscriptions supports_subscriptions BOOLEAN NOT NULL DEFAULT 0;
ALTER TABLE portal CHANGE institutions supports_institutions BOOLEAN NOT NULL DEFAULT 0;
