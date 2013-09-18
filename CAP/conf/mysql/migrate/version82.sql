-- Drop the foreign key constraints from cap_log.requests

-- New database version number:
SET @dbversion = 82;

DROP PROCEDURE IF EXISTS Migrate;
DELIMITER //
CREATE PROCEDURE Migrate()
BEGIN
    SELECT value INTO @current_version FROM info WHERE NAME = 'version';

    IF @current_version = @dbversion - 1 THEN

        --
        -- BEGIN MIGRATION STEPS
        --

        ALTER TABLE cap_log.requests
            DROP FOREIGN KEY requests_ibfk_1,
            DROP FOREIGN KEY requests_ibfk_2;

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

