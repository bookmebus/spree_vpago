source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

group :development, :test do
  gem 'brakeman'
  gem 'rails-controller-testing'
  gem 'vcr'
  gem 'webmock'
end

group :test do
  gem 'shoulda-matchers'
end

gemspec
