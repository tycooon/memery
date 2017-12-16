# frozen_string_literal: true

require "mememaster/version"

module Mememaster
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
    mod = @_mememaster_module

    @_mememaster_module.module_eval do
      define_method(method_name) do |*args|
        @_mememaster_memoized_values ||= {}

        key = [method_name, mod.object_id].join("_").to_sym
        store = @_mememaster_memoized_values[key] ||= {}

        if store.key?(args)
          store[args]
        else
          store[args] = super(*args)
        end
      end
    end
  end
end
