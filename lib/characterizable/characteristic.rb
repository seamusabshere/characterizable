module Characterizable
  class Characteristic
    attr_reader :base, :name, :trumps, :prerequisite, :display, :options

    def initialize(base, name, options = {}, &block)
      @base = base
      @name = name
      @trumps = Array.wrap options.delete(:trumps)
      @prerequisite = options.delete(:prerequisite)
      @display = options.delete(:display)
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

    def display(universe)
      val = value(universe)
      @display.call(val) if @display and val
    end

    def known?(universe)
      not value(universe).nil?
    end

    def potential?(universe)
      not known?(universe) and revealed? universe and not trumped? universe
    end

    def effective?(universe, ignoring = [])
      known?(universe) and
        revealed?(universe) and not
        trumped?(universe, ignoring)
    end

    def trumped?(universe, ignoring = [])
      characteristics.each do |_, other|
        next if ignoring.include?(other.name)

        if other.can_trump? self
          if can_trump?(other)
            return mutually_trumped?(universe, other, ignoring) 
          elsif other.effective?(universe, ignoring + [name])
            return true
          end
        end
      end
      false
    end

    def can_trump?(other)
      trumps.include?(other.name)
    end

    def mutually_trumped?(universe, other, ignoring)
      # special case: mutual trumping. current characteristic is trumped if its friend is otherwise effective and it is not otherwise effective
      other.effective?(universe, ignoring + [name]) and not effective?(universe, ignoring + [other.name])
    end

    def revealed?(universe)
      return true if prerequisite.nil?
      characteristics[prerequisite].effective? universe
    end

    include Blockenspiel::DSL
    def reveals(other_name, other_options = {}, &block)
      base.has other_name, other_options.merge(:prerequisite => name), &block
    end

    def displays(&block)
      @display = block
    end
  end
end
