require 'blockenspiel'
require 'active_support'
require 'active_support/version'
%w{
  active_support/core_ext/class/attribute_accessors
  active_support/core_ext/object/blank
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ActiveSupport::VERSION::MAJOR == 3

module Characterizable
  def self.included(klass)
    klass.cattr_accessor :characterizable_base
    klass.extend ClassMethods
  end
  
  def known_characteristics
    characterizable_base.characteristics.keys.reject do |name|
      send(name).nil?
    end
  end
  
  def unknown_characteristics
    characterizable_base.characteristics.keys.select do |name|
      send(name).nil?
    end
  end
  
  module ClassMethods
    def characterize(&block)
      self.characterizable_base = Characterizable::Base.new
      Blockenspiel.invoke block, characterizable_base
    end
  end
  
  class Base
    include Blockenspiel::DSL
    def characteristics
      @_characteristics ||= ActiveSupport::OrderedHash.new
    end
    def has(name)
      name = name.to_sym
      characteristics[name] = Characteristic.new self, name
    end
  end
  
  class Characteristic
    attr_reader :name
    def initialize(base, name)
      @name = name
    end
  end
end
