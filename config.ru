# Run this directly with rackup

require 'paynearme/callbacks/api'

use Rack::Reloader
run Paynearme::Callbacks::API