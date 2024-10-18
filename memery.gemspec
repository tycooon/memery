# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "memery/version"

Gem::Specification.new do |spec|
  spec.required_ruby_version = ">= 3.0.0"

  spec.name          = "memery"
  spec.version       = Memery::VERSION
  spec.authors       = ["Yuri Smirnov"]
  spec.email         = ["tycoooon@gmail.com"]

  spec.summary       = "A gem for memoization."
  spec.description   = "Memery is a gem for memoization."
  spec.homepage      = "https://github.com/tycooon/memery"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]
end
