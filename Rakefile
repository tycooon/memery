# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:lint)

task default: %i[lint spec]

desc "run benchmark"
task :benchmark do
  require_relative "benchmark"
end
