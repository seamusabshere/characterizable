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
  active_support/core_ext/module/delegation
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ActiveSupport::VERSION::MAJOR == 3

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
  
  class BetterHash < ::Hash
    # In Ruby 1.9, running select/reject/etc. gives you back a hash
    if RUBY_VERSION < '1.9'
      def to_hash
        Hash.new.replace self
      end
      def to_json(*)
        to_hash.to_json
      end
      def reject(&block)
        inject(Characterizable::BetterHash.new) do |memo, ary|
          unless block.call(*ary)
            memo[ary[0]] = ary[1]
          end
          memo
        end
      end
      def select(&block)
        inject(Characterizable::BetterHash.new) do |memo, ary|
          if block.call(*ary)
            memo[ary[0]] = ary[1]
          end
          memo
        end
      end
      # I need this because otherwise it will try to do self.class.new on subclasses
      # which would get "0 for 1" arguments error with Snapshot, among other things
      def slice(*keep)
        inject(Characterizable::BetterHash.new) do |memo, ary|
          if keep.include?(ary[0])
            memo[ary[0]] = ary[1]
          end
          memo
        end
      end
    end
  end
  
  class Snapshot < BetterHash
    attr_reader :target
    def initialize(target)
      @target = target
      _take_snapshot
    end
    def _take_snapshot
      target.characterizable_base.characteristics.each do |_, c|
        if c.known?(target)
          if c.effective?(target)
            self[c.name] = c.value(target)
          elsif !c.untrumped?(target)
            trumped_keys.push c.name
          elsif !c.revealed?(target)
            wasted_keys.push c.name
            lacking_keys.push c.prerequisite
          end
        end
      end
    end
    def []=(key, value)
      target.expire_snapshot!
      super
    end
    def wasted_keys
      @wasted_keys ||= Array.new
    end
    def trumped_keys
      @trumped_keys ||= Array.new
    end
    def lacking_keys
      @lacking_keys ||= Array.new
    end
    def effective
      target.characterizable_base.characteristics.select { |_, c| c.effective?(self) }
    end
    def potential
      target.characterizable_base.characteristics.select { |_, c| c.potential?(self) }
    end
    def wasted
      target.characterizable_base.characteristics.slice(*wasted_keys)
    end
    def lacking
      target.characterizable_base.characteristics.slice(*(lacking_keys - wasted_keys))
    end
    def trumped
      target.characterizable_base.characteristics.slice(*trumped_keys)
    end
  end
  
  module ClassMethods
    def characterize(&block)
      self.characterizable_base ||= Characterizable::Base.new self
      Blockenspiel.invoke block, characterizable_base
    end
    delegate :characteristics, :to => :characterizable_base
  end
  
  class CharacteristicAlreadyDefined < ArgumentError
  end
  
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
        klass.define_attribute_methods if klass.respond_to?(:attribute_methods_generated?) and !klass.attribute_methods_generated?
      rescue
        # for example, if a table doesn't exist... just ignore it
      end
      klass.module_eval(%{
        def #{name}_with_expire_snapshot=(new_#{name})
          expire_snapshot!
          self.#{name}_without_expire_snapshot = new_#{name}
        end
        alias_method_chain :#{name}=, :expire_snapshot
      }, __FILE__, __LINE__) if klass.instance_methods.include?("#{name}=")
    end
  end
  class Characteristic
    attr_reader :base
    attr_reader :name
    attr_reader :trumps
    attr_reader :prerequisite
    attr_reader :options
    def initialize(base, name, options = {}, &block)
      @base = base
      @name = name
      @trumps = Array.wrap options.delete(:trumps)
      @prerequisite = options.delete(:prerequisite)
      @options = options
      Blockenspiel.invoke block, self if block_given?
    end
    def to_json(*)
      { :name => name, :trumps => trumps, :prerequisite => prerequisite, :options => options }.to_json
    end
    def inspect
      "<Characterizable::Characteristic name=#{name.inspect} trumps=#{trumps.inspect} prerequisite=#{prerequisite.inspect} options=#{options.inspect}>"
    end
    def trumped_by
      @_trumped_by ||= characteristics.select { |_, c| c.trumps.include? name }
    end
    delegate :characteristics, :to => :base
    def value(target)
      case target
      when Hash
        target[name]
      else
        target.send name if target.respond_to?(name)
      end
    end
    def known?(target)
      !value(target).nil?
    end
    def potential?(target)
      !known?(target) and revealed? target and untrumped? target
    end
    def effective?(target)
      known?(target) and revealed? target and untrumped? target
    end
    def untrumped?(target)
      return true if trumped_by.empty?
      trumped_by.none? do |_, c|
        c.effective? target
      end
    end
    def revealed?(target)
      return true if prerequisite.nil?
      characteristics[prerequisite].effective? target
    end
    include Blockenspiel::DSL
    def reveals(other_name, other_options = {}, &block)
      base.has other_name, other_options.merge(:prerequisite => name), &block
    end
  end
end
