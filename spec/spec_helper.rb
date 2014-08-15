require 'puppetlabs_spec_helper/module_spec_helper'
require 'hiera'

# See https://github.com/rodjek/rspec-puppet#hiera-integration
Hiera_yaml = 'spec/fixtures/hiera/hiera.yaml'

RSpec.configure do |c|
  c.before do
    # avoid "Only root can execute commands as other users"
    Puppet.features.stubs(:root? => true)
  end
end

if RUBY_VERSION =~ /1.9/
    Encoding.default_external = Encoding::UTF_8
    Encoding.default_internal = Encoding::UTF_8
end