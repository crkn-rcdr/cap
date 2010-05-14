set :application, "CAP"
set :repository,  "http://dev.cihm/svn/cap/trunk"
set :keep_releases, 3

set :scm, :subversion
set :user, "deployer"

set :deploy_to, "/opt/cap"
set :deploy_via, :remote_cache

set :app_var, "/opt/cap-var"

after "deploy:setup", :custom_chown, :deploy_libs, :configure
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

task :configure do
   
    location = 'CAP/cap.conf.erb' 
    template = File.read(location)
    config=ERB.new(template)
    run "mkdir -p #{shared_path}/config"
    put config.result(binding), "#{shared_path}/config/cap.conf"
end

task :after_update_code do
    run "ln -nfs #{shared_path}/config/cap.conf #{release_path}/CAP/cap.conf"
end

    
task :deploy_libs do
    sudo "svn co http://192.168.1.132/svn/cap-libs/debian-amd64 /opt/cap-libs"
end

task :uname do
    run "uname -a"
end
