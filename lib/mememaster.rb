# frozen_string_literal: true

require "mememaster/version"

module Mememaster
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
    else
      :public
    end
  end

  module ClassMethods
    def memoize(method_name)
      prepend_mememaster_module!
      define_memoized_method!(method_name)
    end

    private

    def prepend_mememaster_module!
      return if defined?(@_mememaster_module)
      @_mememaster_module = Module.new
      prepend @_mememaster_module
    end

    def define_memoized_method!(method_name)
      mod_id = @_mememaster_module.object_id
      visibility = Mememaster.method_visibility(self, method_name)

      @_mememaster_module.module_eval do
        define_method(method_name) do |*args|
          @_mememaster_memoized_values ||= {}

          key = [method_name, mod_id].join("_").to_sym
          store = @_mememaster_memoized_values[key] ||= {}

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
    def clear_mememaster_cache!
      @_mememaster_memoized_values = {}
    end
  end
end
