# frozen_string_literal: true

# https://bugs.ruby-lang.org/issues/14909#note-7
require "warning"
Warning.ignore :keyword_separation, __FILE__

require "memery/version"

module Memery
  class << self
    def included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end

    def method_visibility(klass, method_name)
      case
      when klass.private_method_defined?(method_name)
        :private
      when klass.protected_method_defined?(method_name)
        :protected
      when klass.public_method_defined?(method_name)
        :public
      end
    end

    def monotonic_clock
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end

  module ClassMethods
    def memoize(method_name, condition: nil, ttl: nil)
      prepend_memery_module!
      define_memoized_method!(method_name, condition: condition, ttl: ttl)
      method_name
    end

    def memoized?(method_name)
      return false unless defined?(@_memery_module)

      @_memery_module.method_defined?(method_name) ||
        @_memery_module.private_method_defined?(method_name)
    end

    private

    def prepend_memery_module!
      return if defined?(@_memery_module)
      @_memery_module = Module.new
      prepend @_memery_module
    end

    def define_memoized_method!(method_name, condition: nil, ttl: nil)
      visibility = Memery.method_visibility(self, method_name)
      raise ArgumentError, "Method #{method_name} is not defined on #{self}" unless visibility

      method_key = "#{method_name}_#{@_memery_module.object_id}"

      # Change to regular call of `define_method` after Ruby 2.4 drop
      @_memery_module.send :define_method, method_name, (lambda do |*args, &block|
        if block || (condition && !instance_exec(&condition))
          return super(*args, &block)
        end

        store = (@_memery_memoized_values ||= {})[method_key] ||= {}

        if store.key?(args) &&
          (ttl.nil? || Memery.monotonic_clock <= store[args][:time] + ttl)
          return store[args][:result]
        end

        result = super(*args)
        @_memery_memoized_values[method_key][args] =
          { result: result, time: Memery.monotonic_clock }
        result
      end)

      @_memery_module.send(visibility, method_name)
    end
  end

  module InstanceMethods
    def clear_memery_cache!
      @_memery_memoized_values = {}
    end
  end
end
