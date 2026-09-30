source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

group :development, :test do
  gem 'brakeman'
  gem 'byebug'
  gem 'rails-controller-testing'
  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'pg'
  gem 'spree_dev_tools'
end

group :test do
  gem 'shoulda-matchers'
end

gem 'jwt'

gemspec
