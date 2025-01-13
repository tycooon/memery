# frozen_string_literal: true

require "memery/version"

module Memery
  class << self
    attr_accessor :use_hashed_arguments

    def monotonic_clock
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end

  @use_hashed_arguments = true

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
    def memoize(*method_names, condition: nil, ttl: nil)
      prepend_memery_module!
      method_names.each do |method_name|
        define_memoized_method!(method_name, condition: condition, ttl: ttl)
      end
      method_names.length > 1 ? method_names : method_names.first
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
      prepend(@_memery_module)
    end

    def define_memoized_method!(method_name, **options)
      @_memery_module.define_memoized_method!(self, method_name, **options)
    end

    module MemoizationModule
      Cache = Struct.new(:result, :time) do
        def fresh?(ttl)
          return true if ttl.nil?
          Memery.monotonic_clock <= time + ttl
        end
      end

      # rubocop:disable Metrics/MethodLength
      def define_memoized_method!(klass, method_name, condition: nil, ttl: nil)
        # Include a suffix in the method key to differentiate between methods of the same name
        # being memoized throughout a class inheritance hierarchy
        method_key = "#{method_name}_#{klass.name || object_id}"
        original_visibility = method_visibility(klass, method_name)

        define_method(method_name) do |*args, &block|
          if block || (condition && !instance_exec(&condition))
            return super(*args, &block)
          end

          cache_store = (@_memery_memoized_values ||= {})
          cache_key = if args.empty?
                        method_key
                      else
                        key_parts = [method_key, *args]
                        Memery.use_hashed_arguments ? key_parts.hash : key_parts
                      end
          cache = cache_store[cache_key]

          return cache.result if cache&.fresh?(ttl)

          result = super(*args)
          new_cache = Cache.new(result, Memery.monotonic_clock)
          cache_store[cache_key] = new_cache

          result
        end

        ruby2_keywords(method_name)
        send(original_visibility, method_name)
      end
      # rubocop:enable Metrics/MethodLength

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
