-- http://redmine.c7a.ca/issues/5122

USE cap;

-- drop log/stats tables, as that work is now done elsewhere
DROP TABLE IF EXISTS stats_usage_portal, stats_usage_institution, cap_log.requests; 

