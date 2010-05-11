require 'blockenspiel'
require 'active_support'
require 'active_support/version'
%w{
  active_support/core_ext/class/attribute_accessors
  active_support/core_ext/object/blank
  active_support/core_ext/array/wrap
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
  
  module ClassMethods
    def characterize(&block)
      self.characterizable_base = Characterizable::Base.new
      Blockenspiel.invoke block, characterizable_base
    end
  end
  
  # don't want to use a Hash, because that would be annoying to select from
  class ArrayOfCharacteristics < Array
    def [](str_or_else)
      case str_or_else
      when String, Symbol
        detect { |c| c.name == str_or_else }
      else
        super
      end
    end
  end
  
  class Base
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
    def initialize(base, name, options = {}, &block)
      @base = base
      @name = name.to_sym
      @trumps = Array.wrap(options[:trumps])
      @prerequisite = options[:prerequisite]
      Blockenspiel.invoke block, self if block_given?
    end
    def unknown?(obj)
      obj.send(name).nil?
    end
    def known?(obj)
      not unknown?(obj)
    end
    def trumped?(obj)
      base.characteristics.any? do |c|
        c.known?(obj) and c.trumps.include?(name)
      end
    end
    def requited?(obj)
      return true if prerequisite.nil?
      base.characteristics[prerequisite].known? obj
    end
    include Blockenspiel::DSL
    def reveals(name, options = {}, &block)
      base.has name, options.merge(:prerequisite => name), &block
    end
  end
end
