source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'spree', github: 'spree/spree', branch: '4-2-stable'

group :development, :test do
  gem 'brakeman'
  gem 'rails-controller-testing'
end

gemspec
