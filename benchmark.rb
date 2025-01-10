# frozen_string_literal: true

require "bundler/setup"
Bundler.setup

require "benchmark"
require "benchmark/ips"
require "benchmark/memory"

puts "```ruby"
puts File.read(__FILE__)
puts "```"
puts
puts "### Output"
puts
puts "```"

require_relative "lib/memery"

class Foo
  class << self
    include Memery

    def base_find(char)
      ("a".."k").find { |letter| letter == char }
    end

    memoize def find_z
      base_find("z")
    end

    memoize def find_new(char)
      base_find(char)
    end

    memoize def find_optional(*)
      base_find("z")
    end
  end
end

def test_no_args
  Foo.find_z
end

def test_with_args
  Foo.find_new("d")
end

def test_empty_args
  Foo.find_optional
end

Benchmark.ips do |x|
  x.report("test_no_args") { test_no_args }
end

Benchmark.memory do |x|
  x.report("test_no_args") { 100.times { test_no_args } }
end

Benchmark.ips do |x|
  x.report("test_empty_args") { test_empty_args }
end

Benchmark.memory do |x|
  x.report("test_empty_args") { 100.times { test_empty_args } }
end

Benchmark.ips do |x|
  x.report("test_with_args") { test_with_args }
end

Benchmark.memory do |x|
  x.report("test_with_args") { 100.times { test_with_args } }
end

Memery.use_hashed_arguments = false
Benchmark.ips do |x|
  x.report("test_with_args_no_hash") { test_with_args }
end

Benchmark.memory do |x|
  x.report("test_with_args_no_hash") { 100.times { test_with_args } }
end
Memery.use_hashed_arguments = true

puts "```"
