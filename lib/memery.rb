# frozen_string_literal: true

require "memery/version"

module Memery
  def self.included(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
  end

  def self.method_visibility(klass, method_name)
    case
    when klass.private_method_defined?(method_name)
      :private
    when klass.protected_method_defined?(method_name)
      :protected
    when klass.public_method_defined?(method_name)
      :public
    end
  end

  module ClassMethods
    def memoize(method_name, condition: nil)
      prepend_memery_module!
      define_memoized_method!(method_name, condition: condition)
    end

    private

    def prepend_memery_module!
      return if defined?(@_memery_module)
      @_memery_module = Module.new
      prepend @_memery_module
    end

    def define_memoized_method!(method_name, condition: nil)
      mod_id = @_memery_module.object_id
      visibility = Memery.method_visibility(self, method_name)
      raise ArgumentError, "Method #{method_name} is not defined on #{self}" unless visibility

      @_memery_module.module_eval do
        define_method(method_name) do |*args, &block|
          if block || (condition && !instance_exec(&condition))
            return super(*args, &block)
          end

          key = "#{method_name}_#{mod_id}"

          store = @_memery_memoized_values&.[](key)

          return store[args] if store&.key?(args)

          @_memery_memoized_values ||= {}
          @_memery_memoized_values[key] ||= {}
          @_memery_memoized_values[key][args] = super(*args)
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
