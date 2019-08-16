# frozen_string_literal: true

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
    end

    private

    def prepend_memery_module!
      return if defined?(@_memery_module)
      @_memery_module = Module.new
      prepend @_memery_module
    end

    def define_memoized_method!(method_name, condition: nil, ttl: nil)
      mod_id = @_memery_module.object_id
      visibility = Memery.method_visibility(self, method_name)
      raise ArgumentError, "Method #{method_name} is not defined on #{self}" unless visibility

      @_memery_module.module_eval do
        define_method(method_name) do |*args, &block|
          if block || (condition && !instance_exec(&condition))
            return super(*args, &block)
          end

          @_memery_memoized_values ||= {}
          key = "#{method_name}_#{mod_id}"
          @_memery_memoized_values[key] ||= {}
          store = @_memery_memoized_values[key] || {}

          if store.key?(args) && (ttl.nil? || Memery.monotonic_clock <= store[args][:time] + ttl)
            return store[args][:result]
          end

          super(*args).tap do |result|
            @_memery_memoized_values[key][args] =
              { result: result, time: Memery.monotonic_clock }
          end
        end

        send(visibility, method_name)
      end
    end
  end

  module InstanceMethods
    def clear_memery_cache!
      @_memery_memoized_values = {}
    end
  end
end
