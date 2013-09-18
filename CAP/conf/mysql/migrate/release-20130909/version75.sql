-- CAP Database version 75:
-- Change the portals table to replace the access_all field with three
-- access categories (open, free, premium) to allow different categories
-- of users to access different categories of documents

CREATE TABLE portal_access (
    portal_id VARCHAR(64) NOT NULL,
    level INT NOT NULL,
    preview INT NOT NULL DEFAULT 0,
    content INT NOT NULL DEFAULT 0,
    metadata INT NOT NULL DEFAULT 0,
    resize INT NOT NULL DEFAULT 0,
    download INT NOT NULL DEFAULT 0,
    purchase INT NOT NULL DEFAULT 0,
    searching INT NOT NULL DEFAULT 0,
    browse INT NOT NULL DEFAULT 0,
    FOREIGN KEY(portal_id) REFERENCES portal(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY(portal_id,  level)
) ENGINE=INNODB DEFAULT CHARSET=utf8;
INSERT INTO portal_access(portal_id, level, preview, content, metadata, resize, download, purchase, searching, browse)
    SELECT id, 0, access_preview, access_all, access_all, access_resize, access_download, access_purchase, access_search, access_browse FROM portal;
INSERT INTO portal_access(portal_id, level, preview, content, metadata, resize, download, purchase, searching, browse)
    SELECT id, 1, access_preview, access_all, access_all, access_resize, access_download, access_purchase, access_search, access_browse FROM portal;
INSERT INTO portal_access(portal_id, level, preview, content, metadata, resize, download, purchase, searching, browse)
    SELECT id, 2, access_preview, access_all, access_all, access_resize, access_download, access_purchase, access_search, access_browse FROM portal;

-- Set the new table version
UPDATE info SET value = '75' WHERE name = 'version';
