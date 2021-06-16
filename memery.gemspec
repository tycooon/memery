# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "memery/version"

Gem::Specification.new do |spec|
  spec.required_ruby_version = ">= 2.5.0"

  spec.name          = "memery"
  spec.version       = Memery::VERSION
  spec.authors       = ["Yuri Smirnov"]
  spec.email         = ["tycooon@yandex.ru"]

  spec.summary       = "A gem for memoization."
  spec.description   = "Memery is a gem for memoization."
  spec.homepage      = "https://github.com/tycooon/memery"
  spec.changelog_uri = "https://github.com/tycooon/memery/blob/master/CHANGELOG.md"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "ruby2_keywords", "~> 0.0.2"

  spec.add_development_dependency "activesupport"
  spec.add_development_dependency "benchmark-ips"
  spec.add_development_dependency "benchmark-memory"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop-config-umbrellio"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-lcov"
end
