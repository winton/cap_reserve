require 'pp'

$root = File.expand_path('../../', __FILE__)
require "#{$root}/lib/cap_reserve/gems"

CapReserve::Gems.activate :rspec

require "#{$root}/lib/cap_reserve"

Spec::Runner.configure do |config|
end