module Characterizable
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
    def as_json(*)
      { :name => name, :trumps => trumps, :prerequisite => prerequisite, :options => options }
    end
    def inspect
      "<Characterizable::Characteristic name=#{name.inspect} trumps=#{trumps.inspect} prerequisite=#{prerequisite.inspect} options=#{options.inspect}>"
    end
    def characteristics
      base.characteristics
    end
    def value(universe)
      case universe
      when Hash
        universe[name]
      else
        universe.send name if universe.respond_to?(name)
      end
    end
    def known?(universe)
      not value(universe).nil?
    end
    def potential?(universe)
      not known?(universe) and revealed? universe and not trumped? universe
    end
    def effective?(universe, ignoring = nil)
      known?(universe) and revealed? universe and not trumped? universe, ignoring
    end
    def trumped?(universe, ignoring = nil)
      characteristics.each do |_, other|
        if other.trumps.include? name and not ignoring == other.name
          if trumps.include? other.name
            # special case: mutual trumping. current characteristic is trumped if its friend is otherwise effective and it is not otherwise effective
            return true if other.effective? universe, name and not effective? universe, other.name
          else
            return true if other.effective? universe
          end
        end
      end
      false
    end
    def revealed?(universe)
      return true if prerequisite.nil?
      characteristics[prerequisite].effective? universe
    end
    include Blockenspiel::DSL
    def reveals(other_name, other_options = {}, &block)
      base.has other_name, other_options.merge(:prerequisite => name), &block
    end
  end
end
