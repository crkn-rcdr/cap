-- CAP Database version 77:
-- Add a table to log transcription data

CREATE TABLE cap_log.transcription_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transcriber_id INT,
    FOREIGN KEY(transcriber_id) REFERENCES cap.user(id) ON UPDATE CASCADE ON DELETE SET NULL, reviewer_id INT,
    FOREIGN KEY(reviewer_id) REFERENCES cap.user(id) ON UPDATE CASCADE ON DELETE SET NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('failed', 'passed', 'corrected')
) ENGINE=INNODB DEFAULT CHARSET=utf8;

-- Set the new table version
UPDATE info SET value = '77' WHERE name = 'version';
