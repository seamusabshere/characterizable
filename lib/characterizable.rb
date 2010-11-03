require 'set'
require 'blockenspiel'
require 'active_support'
require 'active_support/version'
%w{
  active_support/core_ext/hash/slice
  active_support/core_ext/class/attribute_accessors
  active_support/core_ext/object/blank
  active_support/core_ext/array/wrap
  active_support/core_ext/module/aliasing
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ActiveSupport::VERSION::MAJOR == 3

$:.unshift File.dirname(__FILE__)
require 'characterizable/base'
require 'characterizable/better_hash'
require 'characterizable/characteristic'
require 'characterizable/snapshot'

module Characterizable
  def self.included(klass)
    klass.cattr_accessor :characterizable_base
    klass.extend ClassMethods
  end
  
  def characteristics
    @_characteristics ||= Snapshot.new self
  end
  
  def expire_snapshot!
    @_characteristics = nil
  end

  def display_characteristic(name)
    characteristic = self.class.characteristics[name]
    characteristic.display(characteristics) if characteristic
  end
  
  module ClassMethods
    def characterize(&block)
      self.characterizable_base ||= Characterizable::Base.new self
      Blockenspiel.invoke block, characterizable_base
    end
    def characteristics
      characterizable_base.characteristics
    end
  end
  
  class CharacteristicAlreadyDefined < ArgumentError; end
end
