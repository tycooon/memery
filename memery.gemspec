# frozen_string_literal: true

require_relative 'lib/memery/version'

Gem::Specification.new do |spec|
  spec.name          = 'memery'
  spec.version       = Memery::VERSION
  spec.authors       = ['Yuri Smirnov']
  spec.email         = ['tycooon@yandex.ru']

  spec.summary       = 'A gem for memoization.'
  spec.description   = 'Memery is a gem for memoization.'
  spec.homepage      = 'https://github.com/tycooon/memery'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'ruby2_keywords', '~> 0.0.2'

  spec.add_development_dependency 'activesupport', '~> 6.0'
  spec.add_development_dependency 'benchmark-ips', '~> 2.0'
  spec.add_development_dependency 'benchmark-memory', '~> 0.1.0'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'coveralls_reborn', '~> 0.16.0'
  spec.add_development_dependency 'pry-byebug', '~> 3.9'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.86.0'
  spec.add_development_dependency 'rubocop-performance', '~> 1.5'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.38'
  spec.add_development_dependency 'simplecov', '~> 0.18.0'
end
