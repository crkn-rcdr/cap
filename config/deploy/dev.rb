# DEV-specific deployment configuration
# please put general deployment config in config/deploy.rb

role :appservers, "dev.cihm"

set :select_uri, "http://localhost:8984/solr/select"
set :update_uri, "http://localhost:8984/solr/update"

set :deploy_to, "/opt/cap-dev/cap"
set :app_var, "/opt/cap-dev/var"
set :debug_var, "true"

set :repository, "http://dev.cihm/svn/cap/trunk"

set :db_user, "cap"
set :db_password, ""

set :cap_libs,   "/opt/cap-dev/cap-libs"
set :netpbm_var, "#{cap_libs}/netpbm/bin"

set :deploy_via, :remote_cache

task :mk_init do
    sudo "ln -fs #{current_path}/tools/apache_config/dev /etc/apache2/sites-available"
    sudo "a2ensite dev"
    sudo "ln -fs  #{current_path}/tools/cap-dev /etc/init.d"
end

