# Run this directly with rackup

require 'paynearme/callbacks/api'

use Rack::Reloader
use Rack::CommonLogger

run Paynearme::Callbacks::API