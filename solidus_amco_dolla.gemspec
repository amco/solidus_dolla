# encoding: UTF-8

$:.push File.expand_path('../lib', __FILE__)
require 'solidus_amco_dolla/version'

Gem::Specification.new do |s|
  s.name        = 'solidus_amco_dolla'
  s.version     = SolidusAmcoDolla::VERSION
  s.summary     = 'Amco Dolla Payment Gateway Solidus Integration'
  s.description = 'Amco Dolla Payment Gateway Solidus Integration'
  s.license     = 'BSD-3-Clause'
  s.author    = 'Mumo Carlos'
  s.email     = 'mumo.crls@gmail.com'

  s.files = Dir["{app,config,db,lib}/**/*", 'LICENSE', 'Rakefile', 'README.md']
  solidus_version = ['>= 1.0', '< 3']

  s.add_dependency 'solidus_core', solidus_version
  s.add_dependency 'solidus_backend', solidus_version
  s.add_dependency 'solidus_api', solidus_version
  s.add_dependency 'solidus_support'
  s.add_dependency 'dolla'

  s.add_development_dependency 'capybara'
  s.add_development_dependency 'poltergeist'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_bot'
  s.add_development_dependency 'factory_bot_rails'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'pry-rails'
  s.add_development_dependency 'pry'
end
