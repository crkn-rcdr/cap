# DEV-specific deployment configuration
# please put general deployment config in config/deploy.rb

role :appservers, "asiago.cihm", "brie.cihm"

set :select_uri, "http://localhost:8989/solr/select"
set :update_uri, "http://localhost:8989/solr/update"

set :deploy_to, "/opt/cap-alpha/cap"
set :app_var, "/opt/cap-alpha/cap-var"
set :debug_var, "true"

set :repository, "http://dev.cihm/svn/cap/branches/alpha"

set :deploy_via, :remote_cache

task :mk_init do
    sudo "ln -fs #{current_path}/tools/apache_config/alpha /etc/apache2/sites-available"
    sudo "a2ensite alpha"
    sudo "ln -fs  #{current_path}/tools/cap-alpha /etc/init.d"
end

