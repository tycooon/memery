# frozen_string_literal: true

require "ruby2_keywords"

require "memery/version"

module Memery
  class << self
    def monotonic_clock
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end

  OUR_BLOCK = lambda do
    extend(ClassMethods)
    include(InstanceMethods)
    extend ModuleMethods if instance_of?(Module)
  end

  private_constant :OUR_BLOCK

  module ModuleMethods
    def included(base = nil, &block)
      if base.nil? && block
        super do
          instance_exec(&block)
          instance_exec(&OUR_BLOCK)
        end
      else
        base.instance_exec(&OUR_BLOCK)
      end
    end
  end

  extend ModuleMethods

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
      @_memery_module = Module.new { extend MemoizationModule }
      prepend @_memery_module
    end

    def define_memoized_method!(*args, **kwargs)
      @_memery_module.public_send __method__, self, *args, **kwargs
    end

    module MemoizationModule
      def define_memoized_method!(klass, method_name, condition: nil, ttl: nil)
        method_key = "#{method_name}_#{object_id}"

        original_visibility = method_visibility(klass, method_name)

        define_method method_name do |*args, &block|
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
        end

        ruby2_keywords method_name

        send original_visibility, method_name
      end

      private

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

    private_constant :MemoizationModule
  end

  module InstanceMethods
    def clear_memery_cache!
      @_memery_memoized_values = {}
    end
  end
end
