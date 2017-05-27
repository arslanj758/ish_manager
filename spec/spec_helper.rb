
ENV["RAILS_ENV"] ||= 'test'
require 'devise'
require File.expand_path("../dummy/config/environment.rb", __FILE__)
require 'rspec/rails'

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!

  config.include Devise::TestHelpers, :type => :helper
  config.include Devise::TestHelpers, :type => :controller

end
