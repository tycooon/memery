# frozen_string_literal: true

require 'bundler/setup'

require 'pry-byebug'

require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
)

SimpleCov.start

require_relative '../lib/memery'
require 'active_support/concern'
