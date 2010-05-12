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
  
  def dirty_characteristics!
    @_characteristics = nil
  end
  
  # hashes that survive as such when you select/reject/slice them
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
    def snapshotted_obj
      survivor_args.first
    end
    def []=(key, value)
      snapshotted_obj.dirty_characteristics!
      super
    end
    def take_snapshot
      snapshotted_obj.characterizable_base.characteristics.each do |k, c|
        if c.known?(snapshotted_obj) and c.requited?(snapshotted_obj) and not c.trumped?(snapshotted_obj)
          self[k] = snapshotted_obj.send c.name
        end
      end
    end
    def known
      snapshotted_obj.characterizable_base.characteristics.select do |_, c|
        c.known?(self) and c.requited?(self) and not c.trumped?(self)
      end
    end
    def unknown
      snapshotted_obj.characterizable_base.characteristics.select do |_, c|
        c.unknown?(self) and c.requited?(self) and not c.trumped?(self)
      end
    end
    def visible_known
      known.reject { |_, c| c.hidden? }
    end
    def visible_unknown
      unknown.reject { |_, c| c.hidden? }
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
        def #{name}_with_dirty_characteristics=(new_#{name})
          dirty_characteristics!
          self.#{name}_without_dirty_characteristics = new_#{name}
        end
        alias_method_chain :#{name}=, :dirty_characteristics
      }, __FILE__, __LINE__) if klass.instance_methods.include?("#{name}=")
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
      @name = name
      @trumps = Array.wrap(options.delete(:trumps))
      @prerequisite = options.delete :prerequisite
      @hidden = options.delete :hidden
      @options = options
      Blockenspiel.invoke block, self if block_given?
    end
    delegate :characteristics, :to => :base
    def value(obj)
      case obj
      when Hash
        obj[name]
      else
        obj.send name
      end
    end
    def unknown?(obj)
      value(obj).nil?
    end
    def known?(obj)
      not unknown?(obj)
    end
    def trumped?(obj)
      characteristics.any? do |_, c|
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
    end
  end
end
