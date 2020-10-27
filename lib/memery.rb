# frozen_string_literal: true

require 'module_methods'
require 'ruby2_keywords'

require_relative 'memery/version'

## Module for memoization
module Memery
  extend ::ModuleMethods::Extension

  class << self
    def monotonic_clock
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def method_visibility(klass, method_name)
      if klass.private_method_defined?(method_name)
        :private
      elsif klass.protected_method_defined?(method_name)
        :protected
      elsif klass.public_method_defined?(method_name)
        :public
      else
        raise ArgumentError, "Method #{method_name} is not defined on #{klass}"
      end
    end
  end

  ## Module for class methods
  module ClassMethods
    def memoized_methods
      @memoized_methods ||= {}
    end

    ## TODO: Resolve this
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def memoize(method_name, condition: nil, ttl: nil)
      original_visibility = Memery.method_visibility(self, method_name)

      original_method = memoized_methods[method_name] = instance_method(method_name)

      undef_method method_name

      define_method method_name do |*args, &block|
        if block || (condition && !instance_exec(&condition))
          return original_method.bind(self).call(*args, &block)
        end

        method_object_id = original_method.object_id

        store =
          ((@_memery_memoized_values ||= {})[method_name] ||= {})[method_object_id] ||= {}

        if store.key?(args) && (ttl.nil? || Memery.monotonic_clock <= store[args][:time] + ttl)
          return store[args][:result]
        end

        result = original_method.bind(self).call(*args)
        @_memery_memoized_values[method_name][method_object_id][args] =
          { result: result, time: Memery.monotonic_clock }
        result
      end

      ruby2_keywords method_name

      send original_visibility, method_name

      method_name
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def memoized?(method_name)
      memoized_methods.key?(method_name)
    end
  end

  def clear_memery_cache!(*method_names)
    if method_names.any?
      method_names.each { |method_name| @_memery_memoized_values[method_name]&.clear }
    elsif defined? @_memery_memoized_values
      @_memery_memoized_values.clear
    end
  end
end
