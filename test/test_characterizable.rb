require 'helper'

# just to see if it hurts
require 'active_support/json'

class Characterizable::Characteristic
  def hidden?
    !!options[:hidden]
  end
end

class Automobile
  attr_accessor :make, :model_year, :model, :variant, :size_class, :hybridity, :daily_distance_estimate
  attr_accessor :record_creation_date
  include Characterizable
  characterize do
    has :make do |make|
      make.reveals :model_year do |model_year|
        model_year.reveals :model, :trumps => :size_class do |model|
          model.reveals :variant, :trumps => :hybridity
        end
      end
    end
    has :record_creation_date, :hidden => true
    has :size_class
    has :hybridity
    has :daily_distance_estimate, :trumps => [:weekly_distance_estimate, :annual_distance_estimate, :daily_duration], :measures => :length #, :weekly_fuel_cost, :annual_fuel_cost]
    has :daily_distance_oracle_estimate, :trumps => :daily_distance_estimate
  end
end

class SimpleAutomobile
  include Characterizable
  attr_accessor :make, :model, :variant

  characterize do
    has :make
    has :model, :display => lambda { |c| "Brand new #{c}" }
    has :variant, :trumps => :model do
      displays { |v| "Featuring #{v}" }
    end
  end
end

class Universe
  include Characterizable
  attr_accessor :matter
  attr_accessor :antimatter
  characterize do
    has :matter, :trumps => :antimatter
    has :antimatter, :trumps => :matter
  end
end

class TestCharacterizable < Test::Unit::TestCase
  should "let you define the effective characteristics of a class" do
    assert_nothing_raised do
      class OnDemandAutomobile
        include Characterizable
        characterize do
          has :make
          has :model
        end
      end
    end
  end

  should "survive as a certain kind of hash" do
    a = SimpleAutomobile.new

    assert_equal Characterizable::BetterHash, SimpleAutomobile.characteristics.class
    assert_equal Characterizable::BetterHash, SimpleAutomobile.characteristics.select { false }.class
    assert_equal Characterizable::BetterHash, SimpleAutomobile.characteristics.slice(:hello).class
    assert_equal Characterizable::BetterHash, SimpleAutomobile.characteristics.merge({:hi => 'there'}).class
    
    assert_equal Characterizable::BetterHash, a.characteristics.effective.class
    assert_equal Characterizable::BetterHash, a.characteristics.effective.select { false }.class
    assert_equal Characterizable::BetterHash, a.characteristics.effective.slice(:hello).class
    assert_equal Characterizable::BetterHash, a.characteristics.effective.merge({:hi => 'there'}).class

    assert_equal Characterizable::BetterHash, a.characteristics.select { false }.class
    assert_equal Characterizable::BetterHash, a.characteristics.slice(:hello).class

    assert_equal Characterizable::Snapshot, a.characteristics.class
    assert_equal Characterizable::Snapshot, a.characteristics.merge({:hi => 'there'}).class
  end
  
  should "not be annoying to work with characteristics on a particular instance" do
    a = SimpleAutomobile.new
    a.make = 'Nissan'
    assert_same_contents [:make], a.characteristics.effective.keys
    assert_same_contents [:make], a.characteristics.effective.select { true }.keys
  end
  
  should "not be annoying to work with characteristics hashes on a class level" do
    assert_same_contents [:make, :model, :variant], SimpleAutomobile.characteristics.keys
    assert_same_contents [:make, :model, :variant], SimpleAutomobile.characteristics.select { true }.keys
  end
  
  should "tell you what characteristics are effective" do
    a = SimpleAutomobile.new
    a.make = 'Ford'
    assert_same_contents [:make], a.characteristics.effective.keys
  end

  should "tell you what characteristics are potential" do
    a = SimpleAutomobile.new
    a.make = 'Ford'
    assert_same_contents [:model, :variant], a.characteristics.potential.keys
  end

  should "present a concise set of effective characteristics by getting rid of those that have been trumped" do
    a = SimpleAutomobile.new
    a.make = 'Ford'
    a.model = 'Taurus'
    a.variant = 'Taurus V6 DOHC'
    assert_same_contents [:make, :variant], a.characteristics.effective.keys
  end

  should "not mention a characteristic as potential if, in fact, it has been trumped" do
    a = SimpleAutomobile.new
    a.make = 'Ford'
    a.variant = 'Taurus V6 DOHC'
    assert_same_contents [], a.characteristics.potential.keys
  end
  
  should "know what's next" do
    a = Automobile.new
    a.make = 'Ford'
    assert_equal true, a.characteristics.potential.keys.include?(:model_year)
  end
  
  should "know what characteristics are wasted and why" do
    a = Automobile.new
    a.hybridity = 'Electric'
    a.variant = 'Taurus V6 DOHC'
    assert_equal 'Electric', a.characteristics[:hybridity]
    assert_equal nil, a.characteristics[:variant]
    assert_same_contents [:hybridity], a.characteristics.effective.keys
    assert_same_contents [:variant], a.characteristics.wasted.keys
    assert_same_contents [:model], a.characteristics.lacking.keys
    assert_same_contents [], a.characteristics.trumped.keys
    a.model = 'Taurus'
    assert_equal 'Electric', a.characteristics[:hybridity]
    assert_equal nil, a.characteristics[:variant]
    assert_equal nil, a.characteristics[:model]
    assert_same_contents [:hybridity], a.characteristics.effective.keys
    assert_same_contents [:variant, :model], a.characteristics.wasted.keys
    assert_same_contents [:model_year], a.characteristics.lacking.keys
    assert_same_contents [], a.characteristics.trumped.keys
    a.model_year = '2006'
    assert_equal 'Electric', a.characteristics[:hybridity]
    assert_equal nil, a.characteristics[:variant]
    assert_equal nil, a.characteristics[:model]
    assert_equal nil, a.characteristics[:model_year]
    assert_same_contents [:hybridity], a.characteristics.effective.keys
    assert_same_contents [:variant, :model, :model_year], a.characteristics.wasted.keys
    assert_same_contents [:make], a.characteristics.lacking.keys
    assert_same_contents [], a.characteristics.trumped.keys
    a.make = 'Ford'
    assert_equal nil, a.characteristics[:hybridity]
    assert_equal 'Taurus V6 DOHC', a.characteristics[:variant]
    assert_equal 'Taurus', a.characteristics[:model]
    assert_equal '2006', a.characteristics[:model_year]
    assert_equal 'Ford', a.characteristics[:make]
    assert_same_contents [:variant, :model, :model_year, :make], a.characteristics.effective.keys
    assert_same_contents [], a.characteristics.wasted.keys
    assert_same_contents [], a.characteristics.lacking.keys
    assert_same_contents [:hybridity], a.characteristics.trumped.keys
  end

  should "not mention a characteristic as potential if it is waiting on something else to be revealed" do
    a = Automobile.new
    assert !a.characteristics.potential.keys.include?(:model_year)
  end

  should "make sure that trumping works even within revealed characteristics" do
    a = Automobile.new
    assert a.characteristics.potential.keys.include?(:size_class)
    a.make = 'Ford'
    a.model_year = 1999
    a.model = 'Taurus'
    a.size_class = 'mid-size'
    assert_same_contents [:make, :model_year, :model], a.characteristics.effective.keys
    assert !a.characteristics.potential.keys.include?(:size_class)
  end

  should "not enforce prerequisites by using an object's setter" do
    a = Automobile.new
    a.make = 'Ford'
    a.model_year = 1999
    a.make = nil
    assert_equal 1999, a.model_year
    assert_equal nil, a.characteristics.effective[:model_year]
  end
  
  should "keep user-defined options on a characteristic" do
    assert_equal :length, Automobile.characteristics[:daily_distance_estimate].options[:measures]
  end
  
  should "not confuse user-defined options with other options" do
    assert !Automobile.characteristics[:daily_distance_estimate].options.has_key?(:trumps)
  end
  
  should "allow the user to add custom functionality to characteristics" do
    assert Automobile.characteristics[:record_creation_date].hidden?
    assert !Automobile.characteristics[:daily_distance_estimate].hidden?
  end
    
  should "be able to access values" do
    a = Automobile.new
    a.make = 'Ford'
    assert_equal 'Ford', a.characteristics[:make]
  end
  
  should "know what is effective on a snapshot" do
    a = Automobile.new
    a.make = 'Ford'
    assert_same_contents [:make], a.characteristics.effective.keys
  end
  
  should "know what is potential on a snapshot" do
    a = Automobile.new
    a.make = 'Ford'
    assert a.characteristics.potential.keys.include?(:model_year)
  end
  
  should "not reveal potential characteristics in snapshots" do
    a = Automobile.new
    a.model_year = 1999
    assert_same_contents [], a.characteristics.effective.keys
    assert_equal nil, a.characteristics[:model_year]
  end
  
  should "not reveal potential characteristics in snapshots, even if it was previously revealed" do
    a = Automobile.new
    a.make = 'Ford'
    a.model_year = 1999
    assert_same_contents [:make, :model_year], a.characteristics.effective.keys
    a.make = nil
    assert_same_contents [], a.characteristics.effective.keys
  end
  
  should "keep snapshots separately" do
    a = Automobile.new
    a.make = 'Ford'
    a.model_year = 1999
    snapshot = a.characteristics
    assert_same_contents [:make, :model_year], snapshot.effective.keys
    a.make = nil
    assert_same_contents [], a.characteristics.effective.keys             # up to date!
    assert_same_contents [:make, :model_year], snapshot.effective.keys    # frozen in time!
  end
    
  should "work when passed around as a snapshot" do
    a = Automobile.new
    a.make = 'Ford'
    snapshot = a.characteristics
    assert_same_contents [:make], snapshot.effective.keys
    assert snapshot.potential.keys.include?(:model_year)
    snapshot[:model_year] = 1999
    assert_equal 1999, snapshot[:model_year]
    assert_same_contents [:make, :model_year], snapshot.effective.keys
    assert !snapshot.potential.keys.include?(:model_year)
    assert_equal nil, a.model_year
    assert_equal nil, a.characteristics[:model_year]
    assert_equal 1999, snapshot[:model_year]
  end
  
  should "appreciate that sometimes characteristics just magically appear" do
    a = Automobile.new
    a.daily_distance_estimate = 15
    snapshot = a.characteristics
    snapshot[:daily_distance_oracle_estimate] = 20
    assert_same_contents [:daily_distance_oracle_estimate], snapshot.effective.keys
    assert_same_contents [:daily_distance_estimate], a.characteristics.effective.keys
  end

  # has :make do |make|
  #   make.reveals :model_year do |model_year|
  #     model_year.reveals :model, :trumps => :size_class do |model|
  #       model.reveals :variant, :trumps => :hybridity
  should "handle revelations on multiple levels" do
    a = Automobile.new
    a.make = 'Ford'
    a.model_year = 1999
    a.model = 'Taurus'
    a.variant = 'Taurus 1999'
    assert_same_contents [:make, :model_year, :model, :variant], a.characteristics.effective.keys
    a.make = nil
    assert_same_contents [], a.characteristics.effective.keys
    a.make = 'Ford'
    assert_same_contents [:make, :model_year, :model, :variant], a.characteristics.effective.keys
    a.model_year = nil
    assert_same_contents [:make], a.characteristics.effective.keys
    a.model_year = 1999
    assert_same_contents [:make, :model_year, :model, :variant], a.characteristics.effective.keys
    a.model = nil
    assert_same_contents [:make, :model_year], a.characteristics.effective.keys
    a.model = 'Taurus'
    assert_same_contents [:make, :model_year, :model, :variant], a.characteristics.effective.keys
    a.variant = nil
    assert_same_contents [:make, :model_year, :model], a.characteristics.effective.keys
  end
  
  should "handle trumping on multiple levels" do
    a = Automobile.new
    a.size_class = 'small' # can be trumped by model
    a.hybridity = 'no' # can be trumped by variant
    a.make = 'Ford'
    a.model_year = 1999
    a.model = 'Taurus'
    a.variant = 'Taurus 1999'
    assert_same_contents [:make, :model_year, :model, :variant], a.characteristics.effective.keys
    a.variant = nil
    assert_same_contents [:make, :model_year, :model, :hybridity], a.characteristics.effective.keys
    a.variant = 'Taurus 1999'
    assert_same_contents [:make, :model_year, :model, :variant], a.characteristics.effective.keys
    a.model = nil # which reveals size class, but also hybridity!
    assert_same_contents [:make, :model_year, :size_class, :hybridity], a.characteristics.effective.keys
    a.model = 'Taurus'
    assert_same_contents [:make, :model_year, :model, :variant], a.characteristics.effective.keys
    a.make = nil
    assert_same_contents [:size_class, :hybridity], a.characteristics.effective.keys
  end
  
  should "allow characterizations to be amended" do
    class Fickle
      include Characterizable
      characterize do
        has :foo
      end
      characterize do
        has :bar
      end
    end
    assert_equal [:bar, :foo], Fickle.characteristics.keys.sort { |a, b| a.to_s <=> b.to_s }
  end
  
  should 'allow characterizations to be sliced' do
    a = Automobile.new
    a.make = 'Ford'
    assert_equal({ :make => 'Ford' }, a.characteristics)
    assert_equal({}, a.characteristics.slice(:dummy))
    assert_equal({ :make => 'Ford' }, a.characteristics.slice(:make))
  end
  
  should 'allow characterizations to be selected' do
    a = Automobile.new
    a.make = 'Ford'
    assert_equal({ :make => 'Ford' }, a.characteristics.select { |k, v| k == :make })
    assert_equal({}, a.characteristics.select { |k, v| k == :dummy })
  end
  
  should 'allow characterizations to be rejected' do
    a = Automobile.new
    a.make = 'Ford'
    assert_equal({ :make => 'Ford' }, a.characteristics.reject { |k, v| k == :dummy })
    assert_equal({}, a.characteristics.reject { |k, v| k == :make })
  end

  should 'not reset snapshot after slicing' do
    a = Automobile.new
    a.make = 'Ford'
    snapshot = a.characteristics.slice(:dummy)
    assert_equal({}, snapshot)
    a.make = 'Nissan'
    assert_equal({}, snapshot)
    assert_equal({}, snapshot.slice(:make))
  end
  
  should 'allow a BetterHash to be turned into a normal Hash' do
    assert_equal Hash, Characterizable::BetterHash.new.to_hash.class
  end
  
  should 'be nice to active_support to_json for characteristics (i.e. BetterHashes)' do
    a = Automobile.new
    a.make = 'Ford'
    assert_nothing_raised do
      a.characteristics.to_json
    end
  end
  
  should 'be nice to active_support to_json for snapshots' do
    a = Automobile.new
    a.make = 'Ford'
    assert_nothing_raised do
      a.characteristics.effective.to_json
    end
  end

  should 'raise an exception if #has is called more than once in a single block' do
    assert_raises ::Characterizable::CharacteristicAlreadyDefined do
      class SimpleAutomobile3
        include Characterizable
        attr_accessor :make
        characterize do
          has :make
          has :make
        end
      end
    end
  end
  
  should 'raise an exception if #has is called more than once in a subclass' do
    assert_raises ::Characterizable::CharacteristicAlreadyDefined do
      class SimpleAutomobile2 < SimpleAutomobile
        include Characterizable
        characterize do
          has :make
        end
      end
    end
  end
  
  should "have mutual trumping cancel itself out instead of causing an infinite loop" do
    a = Universe.new
    assert_equal [], a.characteristics.effective.keys
    assert_equal [:matter, :antimatter], a.characteristics.potential.keys
    assert_equal [], a.characteristics.wasted.keys
    assert_equal [], a.characteristics.lacking.keys
    assert_equal [], a.characteristics.trumped.keys
    a.matter = :foo
    assert_equal [:matter], a.characteristics.effective.keys
    assert_equal [], a.characteristics.potential.keys
    assert_equal [], a.characteristics.wasted.keys
    assert_equal [], a.characteristics.lacking.keys
    assert_equal [], a.characteristics.trumped.keys
    a.antimatter = :bar
    assert_equal [:matter, :antimatter], a.characteristics.effective.keys
    assert_equal [], a.characteristics.potential.keys
    assert_equal [], a.characteristics.wasted.keys
    assert_equal [], a.characteristics.lacking.keys
    assert_equal [], a.characteristics.trumped.keys
    a.matter = nil
    assert_equal [:antimatter], a.characteristics.effective.keys
    assert_equal [], a.characteristics.potential.keys
    assert_equal [], a.characteristics.wasted.keys
    assert_equal [], a.characteristics.lacking.keys
    assert_equal [], a.characteristics.trumped.keys
  end

  should 'display custom formats' do
    sa = SimpleAutomobile.new
    sa.model = 'FIT'
    assert_equal 'Brand new FIT', sa.display_characteristic(:model)
    sa.variant = 'Extreme Edition'
    assert_equal 'Featuring Extreme Edition', sa.display_characteristic(:variant)
  end

  context 'infinite recursion' do
    should 'not happen' do
      c = ComplexAutomobile.new
      c.annual_distance_estimate = "33796.2"
      c.daily_duration = "3.0"
      c.timeframe = "2010-01-01/2011-01-01"
      c.weekly_distance_estimate = "804.672"
      assert_nothing_raised do
        c.characteristics
      end
    end
  end
end
