# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mememaster/version"

Gem::Specification.new do |spec|
  spec.name          = "mememaster"
  spec.version       = Mememaster::VERSION
  spec.authors       = ["Yuri Smirnov"]
  spec.email         = ["tycooon@yandex.ru"]

  spec.summary       = "A gem for memoization."
  spec.description   = "Mememaster is a gem for memoization."
  spec.homepage      = "https://github.com/tycooon/mememaster"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop-config-umbrellio"
end
