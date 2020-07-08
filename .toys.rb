# frozen_string_literal: true

require 'bundler/setup'
Bundler.setup

require 'gem_toys'
expand GemToys::Template,
  version_file_path: File.join(context_directory, 'lib/memery/version.rb'),
  unreleased_title: '## Unreleased Alt Memery'

alias_tool :g, :gem
