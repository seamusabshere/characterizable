require 'blockenspiel'
require 'active_support'
require 'active_support/version'
%w{
  active_support/core_ext/class/attribute_accessors
  active_support/core_ext/object/blank
  active_support/core_ext/array/wrap
  active_support/core_ext/module/aliasing
  active_support/core_ext/module/delegation
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ActiveSupport::VERSION::MAJOR == 3

module Characterizable
  def self.included(klass)
    klass.cattr_accessor :characterizable_base
    klass.extend ClassMethods
  end
  
  def known_characteristics
    characterizable_base.characteristics.select do |c|
      c.known?(self) and not c.trumped?(self)
    end
  end
  
  def unknown_characteristics
    characterizable_base.characteristics.select do |c|
      c.unknown?(self) and c.requited?(self) and not c.trumped?(self)
    end
  end
  
  def visible_known_characteristics
    known_characteristics.reject { |c| c.hidden? }
  end
  
  def visible_unknown_characteristics
    unknown_characteristics.reject { |c| c.hidden? }
  end
  
  module ClassMethods
    def characterize(&block)
      self.characterizable_base = Characterizable::Base.new self
      Blockenspiel.invoke block, characterizable_base
    end
    delegate :characteristics, :to => :characterizable_base
  end
  
  # don't want to use a Hash, because that would be annoying to select from
  class ArrayOfCharacteristics < Array
    def [](key_or_index)
      case key_or_index
      when String, Symbol
        detect { |c| c.name == key_or_index }
      else
        super
      end
    end
  end
  
  class Base
    attr_reader :klass
    def initialize(klass)
      @klass = klass
    end
    def characteristics
      @_characteristics ||= ArrayOfCharacteristics.new
    end
    include Blockenspiel::DSL
    def has(name, options = {}, &block)
      characteristics.push Characteristic.new(self, name, options, &block)
    end
  end
  
  class Characteristic
    attr_reader :base
    attr_reader :name
    attr_reader :trumps
    attr_reader :prerequisite
    attr_reader :hidden
    attr_reader :options
    def initialize(base, name, options = {}, &block)
      @base = base
      @name = name.to_sym
      @trumps = Array.wrap(options.delete(:trumps))
      @prerequisite = options.delete :prerequisite
      @hidden = options.delete :hidden
      @options = options
      Blockenspiel.invoke block, self if block_given?
    end
    delegate :characteristics, :to => :base
    def unknown?(obj)
      obj.send(name).nil?
    end
    def known?(obj)
      not unknown?(obj)
    end
    def trumped?(obj)
      characteristics.any? do |c|
        c.known?(obj) and c.trumps.include?(name)
      end
    end
    def requited?(obj)
      return true if prerequisite.nil?
      characteristics[prerequisite].known? obj
    end
    def hidden?
      hidden
    end
    include Blockenspiel::DSL
    def reveals(other_name, other_options = {}, &block)
      base.has other_name, other_options.merge(:prerequisite => name), &block
      base.klass.module_eval %{
        def #{name}_with_dependent_#{other_name}=(new_#{name})
          if new_#{name}.nil?
            self.#{other_name} = nil
          end
          self.#{name}_without_dependent_#{other_name} = new_#{name}
        end
        alias_method_chain :#{name}=, :dependent_#{other_name}
      }, __FILE__, __LINE__
    end
  end
end
