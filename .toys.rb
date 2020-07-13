# frozen_string_literal: true

include :bundler, static: true

require 'gem_toys'
expand GemToys::Template,
  version_file_path: File.join(context_directory, 'lib/memery/version.rb')

alias_tool :g, :gem
