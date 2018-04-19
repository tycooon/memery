# frozen_string_literal: true

require "memery/version"

module Memery
  def self.included(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
  end

  VISIBILITY_LEVELS = %w[private protected public].freeze

  def self.method_visibility(klass, method_name)
    VISIBILITY_LEVELS.find do |visibility_level|
      klass.public_send("#{visibility_level}_method_defined?", method_name)
    end
  end

  module ClassMethods
    def memoize(method_name)
      prepend_memery_module!
      define_memoized_method!(method_name)
    end

    private

    def prepend_memery_module!
      return if defined?(@_memery_module)
      @_memery_module = Module.new
      prepend @_memery_module
    end

    def define_memoized_method!(method_name)
      mod_id = @_memery_module.object_id
      visibility = Memery.method_visibility(self, method_name)

      @_memery_module.module_eval do
        define_method(method_name) do |*args, &block|
          return super(*args, &block) if block

          @_memery_memoized_values ||= {}

          key = [method_name, mod_id].join("_").to_sym
          store = @_memery_memoized_values[key] ||= {}

          if store.key?(args)
            store[args]
          else
            store[args] = super(*args)
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
