ALTER TABLE stats_usage_institution
       ADD portal_id varchar(64) NOT NULL DEFAULT '',
       DROP PRIMARY KEY,
       ADD PRIMARY KEY (month_starting,institution_id,portal_id);

ALTER TABLE stats_usage_institution
    ADD CONSTRAINT stats_usage_institution_ibfk_2
        FOREIGN KEY(portal_id)
        REFERENCES portal(id)
	ON DELETE CASCADE;
