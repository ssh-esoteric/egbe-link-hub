# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

require 'silencer/logger'

use Silencer::Logger, silence: [ %r{/links/[ps][0-9a-zA-Z]+/api} ]

run Rails.application
