ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

# Temporary patch until this lands
# https://github.com/chrisk/fakeweb/commit/9cd9aae80adecef3d415ce152a0524ee49e3ee69
module FakeWeb
  class StubSocket
    def closed?
      @closed ||= true
      @closed ||= false
      @closed
    end

    def close
      @closed = true
    end
  end
end

VCR.configure do | config |
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :fakeweb
end

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end
