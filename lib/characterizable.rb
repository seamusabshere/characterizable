require 'set'
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
  
  def characteristics
    @_characteristics ||= Snapshot.new self
  end
  
  def expire_snapshot!
    @_characteristics = nil
  end
  
  # hashes that survive as such when you select/reject/slice them
  # they also keep arguments passed to them
  class SurvivorHash < Hash
    attr_reader :survivor_args
    def initialize(*survivor_args)
      @survivor_args = survivor_args
    end
    def reject(&block)
      inject(self.class.new(*survivor_args)) do |memo, ary|
        unless block.call(*ary)
          memo[ary[0]] = ary[1]
        end
        memo
      end
    end
    def select(&block)
      inject(self.class.new(*survivor_args)) do |memo, ary|
        if block.call(*ary)
          memo[ary[0]] = ary[1]
        end
        memo
      end
    end
    def slice(*keys)
      inject(self.class.new(*survivor_args)) do |memo, ary|
        if keys.include?(ary[0])
          memo[ary[0]] = ary[1]
        end
        memo
      end
    end
  end
  
  class Snapshot < SurvivorHash
    def initialize(*survivor_args)
      super
      take_snapshot
    end
    def target
      survivor_args.first
    end
    def []=(key, value)
      target.expire_snapshot!
      super
    end
    def take_snapshot
      target.characterizable_base.characteristics.each do |_, c|
        if c.relevant?(target)
          self[c.name] = c.value(target)
        end
      end
    end
    def relevant
      target.characterizable_base.characteristics.select { |_, c| c.relevant?(self) }
    end
    def irrelevant
      target.characterizable_base.characteristics.select { |_, c| c.irrelevant?(self) }
    end
  end
  
  module ClassMethods
    def characterize(&block)
      self.characterizable_base = Characterizable::Base.new self
      Blockenspiel.invoke block, characterizable_base
    end
    delegate :characteristics, :to => :characterizable_base
  end
  
  class Base
    attr_reader :klass
    def initialize(klass)
      @klass = klass
    end
    def characteristics
      @_characteristics ||= SurvivorHash.new
    end
    include Blockenspiel::DSL
    def has(name, options = {}, &block)
      characteristics[name] = Characteristic.new(self, name, options, &block)
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
    def irrelevant?(target)
      value(target).nil? and revealed? target and untrumped? target
    end
    def relevant?(target)
      !value(target).nil? and revealed? target and untrumped? target
    end
    def untrumped?(target)
      return true if trumped_by.empty?
      trumped_by.none? do |_, c|
        c.relevant? target
      end
    end
    def revealed?(target)
      return true if prerequisite.nil?
      characteristics[prerequisite].relevant? target
    end
    include Blockenspiel::DSL
    def reveals(other_name, other_options = {}, &block)
      base.has other_name, other_options.merge(:prerequisite => name), &block
    end
  end
end
