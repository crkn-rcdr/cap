# PROD-specific deployment configuration
# please put general deployment config in config/deploy.rb

role :appservers, "asiago.cihm", "brie.cihm"
set :select_uri, "http://localhost:8984/solr/select"
set :update_uri, "http://localhost:8984/solr/update"


set :deploy_to, "/opt/cap"

set :app_var, "/opt/cap-var"

set :repository,  "http://dev.cihm/svn/cap/trunk"

