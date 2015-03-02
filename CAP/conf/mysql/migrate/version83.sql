
-- Drop the foreign key constraints from cap_log.requests

-- New database version number:
SET @dbversion = 83;

DROP PROCEDURE IF EXISTS Migrate;
DELIMITER //
CREATE PROCEDURE Migrate()
BEGIN
    SELECT value INTO @current_version FROM info WHERE NAME = 'version';

    IF @current_version = @dbversion - 1 THEN

        --
        -- BEGIN MIGRATION STEPS
        --

        CREATE TABLE `collections` (
            `collection` varchar(32) NOT NULL,
            `title_en` text NOT NULL,
            `title_fr` text NOT NULL,
            `description_en` text NOT NULL,
            `description_fr` text NOT NULL,
            PRIMARY KEY (`collection`)
        ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
        
        CREATE TABLE `collections_titles` (
            `title_identifier` varchar(64) NOT NULL,
            `collection` varchar(32) NOT NULL,
            PRIMARY KEY (`title_identifier`,`collection`),
            KEY `collection` (`collection`),
            CONSTRAINT `collection_fk_1` FOREIGN KEY (`collection`) REFERENCES `collections` (`collection`) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;


        --
        -- END MIGRATION STEPS
        --

        UPDATE info SET value = @dbversion WHERE name = 'version';

    ELSEIF @current_version >= @dbversion THEN

        SELECT CONCAT('Database already at version ', @dbversion, ' so skipping this update.')
            AS 'SKIPPING UPDATE:';

    ELSE
        select CONCAT(
            'This script migrates from CAP database version ', @dbversion - 1,
            '. Your database version is ', @current_version, '.'
        ) AS 'UPDATE FAILED:';
    END IF;
END //
DELIMITER ;

CALL Migrate();
DROP PROCEDURE Migrate;

