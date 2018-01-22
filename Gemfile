source 'https://rubygems.org'

branch = ENV.fetch('SOLIDUS_BRANCH', 'master')
gem 'solidus', github: 'solidusio/solidus', branch: branch
gem 'solidus_auth_devise', github: 'solidusio/solidus_auth_devise', branch: branch

if branch == 'master' || branch >= 'v2.3'
  gem 'rails', '~> 5.1.0'
elsif branch >= 'v2.0'
  gem 'rails', '~> 5.0.0'
  gem 'rails-controller-testing', group: :test
else
  gem 'rails', '~> 4.2.0'
  gem 'rails_test_params_backport', group: :test
end

group :development, :test do
  gem 'i18n-tasks', '~> 0.9' if branch == 'master'
end

gemspec
