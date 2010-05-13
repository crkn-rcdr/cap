set :application, "CAP"
set :repository,  "http://dev.cihm/svn/cap/trunk"
set :keep_releases, 3

set :scm, :subversion
set :user, "deployer"

set :deploy_to, "/opt/cap"
set :deploy_via, :remote_cache

role :web, "192.168.1.111"                          # Your HTTP server, Apache/etc
role :app, "192.168.1.111"                          # Your HTTP server, Apache/etc
role :db, "192.168.1.111"                          # Your HTTP server, Apache/etc

after "deploy:setup", :custom_chown, :deploy_libs
after "deploy", "deploy:cleanup"
after "deploy:migrations", "deploy:cleanup"


task :custom_chown do
    sudo "chown -R #{user} #{deploy_to}"
    sudo "a2ensite voyageur"
    sudo "a2ensite canadianaonline"
    sudo "a2dismod deflate"
    sudo "a2enmod rewrite"
    sudo "ln -fs /opt/cap/current/tools/cap-prod /etc/init.d"
    sudo "ln -fs /opt/cap/current/tools/jetty /etc/init.d"

end


task :deploy_libs do
    sudo "svn co http://192.168.1.132/svn/cap-libs/debian-amd64 /opt/cap-libs"
end

