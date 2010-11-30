#!/usr/bin/ruby
# Merge cap.local and cap.conf.erb to create cap.conf
# Usage:
#   localconf.rb < cap.conf.erb > cap.conf
#   localconf.rb cap.conf.erb > cap.conf
#
#   Make a copy of this file that is not under version control and
#   customize the variables below. Then run the copy to generate an
#   up-to-date cap.conf file from the most recent cap.conf.erb

require 'erb'

# Put your local variables here. Refer to cap.conf.erb for what they mean.

debug_var      = "true"
app_var        = "/tmp"
db_user        = "cap"
db_password    = '""'
netpbm_var     = "/usr/local/bin"
select_uri     = "http://localhost:3000/solr/select"
update_uri     = "http://localhost:3000/solr/update"

# Generate the config file
template = ERB.new(ARGF.read)
puts template.result(binding)
