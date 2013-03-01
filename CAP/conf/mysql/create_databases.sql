/*

Create the required databases and set required permissions

*/
CREATE DATABASE IF NOT EXISTS cap_core;
CREATE DATABASE IF NOT EXISTS cap_log;
CREATE DATABASE IF NOT EXISTS cap;

GRANT SELECT, INSERT, UPDATE, DELETE ON cap_core.* TO 'cap'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON cap_log.* TO 'cap'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON cap.* TO 'cap'@'localhost';
