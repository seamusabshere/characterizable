module Characterizable
  class Base
    attr_reader :klass
    def initialize(klass)
      @klass = klass
    end
    def characteristics
      @_characteristics ||= BetterHash.new
    end
    include Blockenspiel::DSL
    def has(name, options = {}, &block)
      raise CharacteristicAlreadyDefined, "The characteristic #{name} has already been defined on #{klass}!" if characteristics.has_key?(name)
      characteristics[name] = Characteristic.new(self, name, options, &block)
      begin
        # quacks like an activemodel
        klass.define_attribute_methods unless klass.respond_to?(:attribute_methods_generated?) and klass.attribute_methods_generated?
      rescue
        # for example, if a table doesn't exist... just ignore it
      end
      begin
        klass.module_eval(%{
          def #{name}_with_expire_snapshot=(new_#{name})
            expire_snapshot!
            self.#{name}_without_expire_snapshot = new_#{name}
          end
          alias_method_chain :#{name}=, :expire_snapshot
        }, __FILE__, __LINE__) #if klass.instance_methods.include?("#{name}=")
      rescue
      end
    end
  end
end
