# DEV-specific deployment configuration
# please put general deployment config in config/deploy.rb

role :appservers, "asiago.cihm"

set :select_uri, "http://localhost:8989/solr/select"
set :update_uri, "http://localhost:8989/solr/update"

set :deploy_to, "/opt/cap-beta/cap"
set :app_var, "/opt/cap-beta/cap-var"
set :debug_var, "true"

set :repository, "http://dev.cihm/svn/cap/branches/beta"

set :deploy_via, :remote_cache

