-- http://redmine.c7a.ca/issues/4940
-- CAP Cleanup: https://docs.google.com/spreadsheets/d/1Kew6Ml6jrWleyFki99947EnneXflfByzmN-AD0PAPG0/edit#gid=0

USE cap;

-- removes unused flags
ALTER TABLE portal DROP COLUMN supports_transcriptions;
ALTER TABLE user DROP COLUMN credits;
ALTER TABLE user DROP COLUMN can_review;
ALTER TABLE user DROP COLUMN can_transcribe;
ALTER TABLE user DROP COLUMN public_contributions;

-- drops foreign key constraint on cap_core.roles, which is about to be dropped
ALTER TABLE user_roles DROP FOREIGN KEY user_roles_ibfk_2;

-- clean it up
DROP TABLE IF EXISTS user_document, outbound_link, contributor, counter_log, cron_log,
	                 pages, documents, feedback, image_resources, images, language,
	                 media_type, cap_core.roles, search_log, cap_log.transcription_log,
	                 cap_log.title_views, titles_terms, terms, portals_titles, titles,
	                 info;

-- cap_core no longer in use
DROP DATABASE IF EXISTS cap_core;
