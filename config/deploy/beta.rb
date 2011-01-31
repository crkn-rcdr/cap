# DEV-specific deployment configuration
# please put general deployment config in config/deploy.rb

role :appservers, "asiago.cihm", "brie.cihm"

set :select_uri, "http://localhost:8984/solr/select"
set :update_uri, "http://localhost:8984/solr/update"

set :deploy_to, "/opt/cap-beta/cap"
set :app_var, "/opt/cap-beta/cap-var"
set :debug_var, "false"

set :repository, "http://dev.cihm/svn/cap/branches/beta"

set :db_user, "cap"
set :db_password, ""

set :cap_libs,   "/opt/cap-libs"
set :netpbm_var, "#{cap_libs}/netpbm/bin"

set :netpbm_var, "/opt/cap-libs/netpbm/bin"

set :deploy_via, :remote_cache

task :mk_init do
    sudo "ln -fs #{current_path}/tools/apache_config/beta /etc/apache2/sites-available"
    sudo "a2ensite beta"
    sudo "ln -fs  #{current_path}/tools/cap-beta /etc/init.d"
end

