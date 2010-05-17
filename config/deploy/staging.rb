# DEV-specific deployment configuration
# please put general deployment config in config/deploy.rb

role :appservers, "192.168.1.200"

set :select_uri, "http://localhost:8984/solr/select"
set :update_uri, "http://localhost:8984/solr/update"

set :deploy_to, "/opt/cap-staging/cap"
set :app_var, "/opt/cap-staging/cap-var"

set :repository, "http://dev.cihm/svn/cap/tags/staging"

set :deploy_via, :remote_cache

