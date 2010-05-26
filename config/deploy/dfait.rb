# DEV-specific deployment configuration
# please put general deployment config in config/deploy.rb

role :appservers, "asiago.cihm"

set :select_uri, "http://localhost:8985/solr/select"
set :update_uri, "http://localhost:8985/solr/update"

set :deploy_to, "/opt/cap-dfait/cap"
set :app_var, "/opt/cap-dfait/cap-var"

set :repository, "http://dev.cihm/svn/cap/branches/dfait"

set :deploy_via, :remote_cache

