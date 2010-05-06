set :application, "CAP"
set :repository,  "http://dev.cihm/svn/cap/branches/rob-captest"

set :scm, :subversion
set :user, "deployer"

set :deploy_to, "/opt/cap"

role :web, "192.168.1.111"                          # Your HTTP server, Apache/etc
role :app, "192.168.1.111"                          # Your HTTP server, Apache/etc
role :db, "192.168.1.111"                          # Your HTTP server, Apache/etc

after "deploy:setup", :custom_chown

task :custom_chown do
    sudo "chown -R #{user} #{deploy_to}"
    sudo "a2ensite voyageur"
    sudo "a2ensite canadianaonline"
    sudo "a2dismod deflate"
    sudo "a2enmod rewrite"
    sudo "ln -fs /opt/cap/current/tools/cap-prod /etc/init.d"
    sudo "cpan local::lib"
end


task :deploy_libs do
    sudo "svn co http://192.168.1.132/svn/cap-libs/debian-amd64 /opt/cap-libs"
end

