UPDATE info SET value = '61' WHERE name = 'version';

CREATE TABLE images(
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    filename VARCHAR(128) UNIQUE NOT NULL,
    content_type VARCHAR(32) NOT NULL,
    height INT NOT NULL,
    width INT NOT NULL,
    updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES user(id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=INNODB DEFAULT CHARSET=utf8;

CREATE TABLE image_resources(
    image_id INT,
    lang VARCHAR(2),
    resource ENUM('title', 'description'),
    value TEXT,
    PRIMARY KEY (image_id, lang, resource),
    FOREIGN KEY (image_id) REFERENCES images(id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=INNODB DEFAULT CHARSET=utf8;