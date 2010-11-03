module Characterizable
  class Snapshot < BetterHash
    attr_reader :universe
    def initialize(universe)
      @universe = universe
      _take_snapshot
    end
    def _take_snapshot
      universe.characterizable_base.characteristics.each do |_, c|
        if c.known?(universe)
          if c.effective?(universe)
            self[c.name] = c.value(universe)
          elsif c.trumped?(universe)
            trumped_keys.push c.name
          elsif !c.revealed?(universe)
            wasted_keys.push c.name
            lacking_keys.push c.prerequisite
          end
        end
      end
    end
    def []=(key, value)
      universe.expire_snapshot!
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
      universe.characterizable_base.characteristics.select { |_, c| c.effective?(self) }
    end
    def potential
      universe.characterizable_base.characteristics.select { |_, c| c.potential?(self) }
    end
    def wasted
      universe.characterizable_base.characteristics.slice(*wasted_keys)
    end
    def lacking
      universe.characterizable_base.characteristics.slice(*(lacking_keys - wasted_keys))
    end
    def trumped
      universe.characterizable_base.characteristics.slice(*trumped_keys)
    end
  end
end
