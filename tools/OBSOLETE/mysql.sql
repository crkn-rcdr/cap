CREATE DATABASE IF NOT EXISTS cap DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

CREATE TABLE IF NOT EXISTS master_image (
    id      VARCHAR(128)    PRIMARY KEY,
    path    VARCHAR(128)    NOT NULL,
    format  VARCHAR(16)     NOT NULL,
    ctime   INT             NOT NULL,
    bytes   INT             NOT NULL,
    md5     VARCHAR(32)     NOT NULL
);

CREATE TABLE IF NOT EXISTS pimg_cache (
    id       VARCHAR(128)    NOT NULL,
    format   VARCHAR(16)     NOT NULL,
    size     INT             NOT NULL,
    rot      INT             NOT NULL,
    data     LONGBLOB        NOT NULL,
    ctime    INT             NOT NULL,
    atime    DATETIME        NOT NULL,
    acount   INT             NOT NULL,
    PRIMARY KEY(id, format, size, rot)
);


