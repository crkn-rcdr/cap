# DEV-specific deployment configuration
# please put general deployment config in config/deploy.rb
role :appservers, "192.168.1.200"

set :select_uri, "http://localhost:8984/solr/select"
set :update_uri, "http://localhost:8984/solr/update"

