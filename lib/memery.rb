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
    def memoize(method_name)
      visibility = Memery.method_visibility(self, method_name)
      old_method = instance_method(method_name)

      define_method(method_name) do |*args, &block|
        return old_method.bind(self).call(*args, &block) if block

        @_memery_memoized_values ||= {}

        key = :"#{method_name}_#{old_method.object_id}"
        store = @_memery_memoized_values[key] ||= {}

        if store.key?(args)
          store[args]
        else
          store[args] = old_method.bind(self).call(*args)
        end
      end

      send(visibility, method_name)
    end
  end

  module InstanceMethods
    def clear_memery_cache!
      @_memery_memoized_values = {}
    end
  end
end
