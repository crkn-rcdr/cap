INSERT INTO portal SET id = 'canadiana', enabled = 1, supports_users = 1,
access_preview = -1, access_all = -1, access_resize = -1, access_download
= -1, access_purchase = -1;

INSERT INTO portal_lang SET portal_id='canadiana', lang='en', priority=10, title='Canadiana';
INSERT INTO portal_lang SET portal_id='canadiana', lang='fr', priority=0, title='Canadiana';
INSERT INTO portal_host SET id='secure', portal_id='canadiana';
