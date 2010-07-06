# DEV-specific deployment configuration
# please put general deployment config in config/deploy.rb
role :appservers, "192.168.1.200"

set :select_uri, "http://localhost:8984/solr/select"
set :update_uri, "http://localhost:8984/solr/update"

set :deploy_to, "/opt/cap"
set :app_var, "/opt/cap-var"
set :debug_var, "true"

set :repository, "http://dev.cihm/svn/cap/trunk"

set :deploy_via, :remote_cache

