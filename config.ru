# Encode to utf-8 as per http://stackoverflow.com/q/3192128/111884
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Enable logging: http://devcenter.heroku.com/articles/ruby#logging
$stdout.sync = true

# Redirect all urls on production (http://github.com/cwninja/rack-force_domain)
use Rack::ForceDomain, ENV["DOMAIN"]

root = ::File.dirname(__FILE__)
require ::File.join( root, 'web' )
run VistazoApp.new