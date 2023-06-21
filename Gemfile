source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

spree_version = '>= 4.5'
gem 'spree_frontend', spree_version

group :development, :test do
  spree_version = '>= 4.5'
  gem 'spree_frontend', spree_version

  gem 'brakeman'
  gem 'rails-controller-testing'
  gem 'pg'
end

gemspec
