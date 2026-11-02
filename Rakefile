require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
require 'spree/testing_support/extension_rake'

RSpec::Core::RakeTask.new

task :default do
  if Dir['spec/dummy'].empty?
    Rake::Task[:test_app].invoke
    Dir.chdir('../../')
  end
  Rake::Task[:spec].invoke
end

desc 'Generates a dummy app for testing'
task :test_app do
  ENV['LIB_NAME'] = 'spree_vpago'
  Rake::Task['extension:test_app'].invoke

  # spree_backend 4.5's installer runs an unpinned `yarn add @spree/dashboard`, which now resolves to Spree 6's
  # React dashboard that this dummy app's esbuild can't bundle. spree-dashboard.js is then never built and every
  # spec rendering a page fails, so pin the last 4.x-compatible release and rebuild.
  Dir.chdir(File.expand_path('spec/dummy', __dir__)) do
    system('yarn add @spree/dashboard@0.2.1 && yarn build && bundle exec rake assets:precompile', exception: true)
  end
end
