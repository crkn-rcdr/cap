#!/bin/bash

# Built all sitemaps
# This is still a testing/experimental script that needs some refinement
# and eventually made into a cron job.
# Also note: the future removal of portal.conf files will require an
# alternate way of getting portal data.

./sitemap http://localhost:8983/solr search.canadiana.ca /opt/cap-root/current/config/co.conf ./sitemap.xsl /opt/cap-var/sitemap/search/

./sitemap http://localhost:8983/solr eco.canadiana.ca /opt/cap-root/current/config/eco.conf ./sitemap.xsl /opt/cap-var/sitemap/eco/

./sitemap http://localhost:8983/solr agriculture.canadiana.ca /opt/cap-root/current/config/agriculture.conf ./sitemap.xsl /opt/cap-var/sitemap/agriculture/

./sitemap http://localhost:8983/solr dfait-aeci.canadiana.ca /opt/cap-root/current/config/dfait.conf ./sitemap.xsl /opt/cap-var/sitemap/dfait/

./sitemap http://localhost:8983/solr whf.canadiana.ca /opt/cap-root/current/config/whf.conf ./sitemap.xsl /opt/cap-var/sitemap/whf/

./sitemap http://localhost:8983/solr 1812.canadiana.ca /opt/cap-root/current/config/1812.conf ./sitemap.xsl /opt/cap-var/sitemap/1812/
