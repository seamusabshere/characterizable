require 'helper'

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
    # has :fuel_type
    # has :fuel_efficiency, :trumps => [:urbanity, :hybridity], :measures => :length_per_volume
    # has :urbanity, :measures => :percentage
    has :hybridity
    has :daily_distance_estimate, :trumps => [:weekly_distance_estimate, :annual_distance_estimate, :daily_duration], :measures => :length #, :weekly_fuel_cost, :annual_fuel_cost]
    has :daily_distance_oracle_estimate, :trumps => :daily_distance_estimate
    # has :daily_duration, :trumps => [:annual_distance_estimate, :weekly_distance_estimate, :daily_distance_estimate], :measures => :time #, :weekly_fuel_cost, :annual_fuel_cost]
    # has :weekly_distance_estimate, :trumps => [:annual_distance_estimate, :daily_distance_estimate, :daily_duration], :measures => :length #, :weekly_fuel_cost, :annual_fuel_cost]
    # has :annual_distance_estimate, :trumps => [:weekly_distance_estimate, :daily_distance_estimate, :daily_duration], :measures => :length #, :weekly_fuel_cost, :annual_fuel_cost]
    # has :acquisition
    # has :retirement
  end
end

class SimpleAutomobile
  include Characterizable
  attr_accessor :make
  attr_accessor :model
  attr_accessor :variant
  characterize do
    has :make
    has :model
    has :variant, :trumps => :model
  end
end

class TestCharacterizable < Test::Unit::TestCase
  should "let you define the relevant characteristics of a class" do
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

    assert_equal Characterizable::SurvivorHash, SimpleAutomobile.characteristics.class
    assert_equal Characterizable::SurvivorHash, SimpleAutomobile.characteristics.select { false }.class
    assert_equal Characterizable::SurvivorHash, SimpleAutomobile.characteristics.slice(:hello).class
    assert_equal Characterizable::SurvivorHash, SimpleAutomobile.characteristics.merge({:hi => 'there'}).class
    
    assert_equal Characterizable::SurvivorHash, a.characteristics.relevant.class
    assert_equal Characterizable::SurvivorHash, a.characteristics.relevant.select { false }.class
    assert_equal Characterizable::SurvivorHash, a.characteristics.relevant.slice(:hello).class
    assert_equal Characterizable::SurvivorHash, a.characteristics.relevant.merge({:hi => 'there'}).class

    assert_equal Characterizable::Snapshot, a.characteristics.class
    assert_equal Characterizable::Snapshot, a.characteristics.select { false }.class
    assert_equal Characterizable::Snapshot, a.characteristics.slice(:hello).class
    assert_equal Characterizable::Snapshot, a.characteristics.merge({:hi => 'there'}).class
  end
  
  should "tell you what characteristics are relevant" do
    a = SimpleAutomobile.new
    a.make = 'Ford'
    assert_same_contents [:make], a.characteristics.relevant.keys
  end

  should "tell you what characteristics are irrelevant" do
    a = SimpleAutomobile.new
    a.make = 'Ford'
    assert_same_contents [:model, :variant], a.characteristics.irrelevant.keys
  end

  should "present a concise set of relevant characteristics by getting rid of those that have been trumped" do
    a = SimpleAutomobile.new
    a.make = 'Ford'
    a.model = 'Taurus'
    a.variant = 'Taurus V6 DOHC'
    assert_same_contents [:make, :variant], a.characteristics.relevant.keys
  end

  should "not mention a characteristic as irrelevant if, in fact, it has been trumped" do
    a = SimpleAutomobile.new
    a.make = 'Ford'
    a.variant = 'Taurus V6 DOHC'
    assert_same_contents [], a.characteristics.irrelevant.keys
  end

  should "not mention a characteristic as irrelevant if it is waiting on something else to be revealed" do
    a = Automobile.new
    assert !a.characteristics.irrelevant.keys.include?(:model_year)
  end

  should "make sure that trumping works even within revealed characteristics" do
    a = Automobile.new
    assert a.characteristics.irrelevant.keys.include?(:size_class)
    a.make = 'Ford'
    a.model_year = 1999
    a.model = 'Taurus'
    a.size_class = 'mid-size'
    assert_same_contents [:make, :model_year, :model], a.characteristics.relevant.keys
    assert !a.characteristics.irrelevant.keys.include?(:size_class)
  end

  should "not enforce prerequisites by using an object's setter" do
    a = Automobile.new
    a.make = 'Ford'
    a.model_year = 1999
    a.make = nil
    assert_equal 1999, a.model_year
    assert_equal nil, a.characteristics.relevant[:model_year]
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
  
  should "know what is relevant on a snapshot" do
    a = Automobile.new
    a.make = 'Ford'
    assert_same_contents [:make], a.characteristics.relevant.keys
  end
  
  should "know what is irrelevant on a snapshot" do
    a = Automobile.new
    a.make = 'Ford'
    assert a.characteristics.irrelevant.keys.include?(:model_year)
  end
  
  should "not reveal irrelevant characteristics in snapshots" do
    a = Automobile.new
    a.model_year = 1999
    assert_same_contents [], a.characteristics.relevant.keys
    assert_equal nil, a.characteristics[:model_year]
  end
  
  should "not reveal irrelevant characteristics in snapshots, even if it was previously revealed" do
    a = Automobile.new
    a.make = 'Ford'
    a.model_year = 1999
    assert_same_contents [:make, :model_year], a.characteristics.relevant.keys
    a.make = nil
    assert_same_contents [], a.characteristics.relevant.keys
  end
  
  should "keep snapshots separately" do
    a = Automobile.new
    a.make = 'Ford'
    a.model_year = 1999
    snapshot = a.characteristics
    assert_same_contents [:make, :model_year], snapshot.relevant.keys
    a.make = nil
    assert_same_contents [], a.characteristics.relevant.keys
    assert_same_contents [:make, :model_year], snapshot.relevant.keys
  end
    
  should "work when passed around as a snapshot" do
    a = Automobile.new
    a.make = 'Ford'
    snapshot = a.characteristics
    assert_same_contents [:make], snapshot.relevant.keys
    assert snapshot.irrelevant.keys.include?(:model_year)
    snapshot[:model_year] = 1999
    assert_equal 1999, snapshot[:model_year]
    assert_same_contents [:make, :model_year], snapshot.relevant.keys
    assert !snapshot.irrelevant.keys.include?(:model_year)
    assert_equal nil, a.model_year
    assert_equal nil, a.characteristics[:model_year]
    assert_equal 1999, snapshot[:model_year]
  end
  
  should "appreciate that sometimes characteristics just magically appear" do
    a = Automobile.new
    a.daily_distance_estimate = 15
    snapshot = a.characteristics
    snapshot[:daily_distance_oracle_estimate] = 20
    assert_same_contents [:daily_distance_oracle_estimate], snapshot.relevant.keys
    assert_same_contents [:daily_distance_estimate], a.characteristics.relevant.keys
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
    assert_same_contents [:make, :model_year, :model, :variant], a.characteristics.relevant.keys
    a.make = nil
    assert_same_contents [], a.characteristics.relevant.keys
    a.make = 'Ford'
    assert_same_contents [:make, :model_year, :model, :variant], a.characteristics.relevant.keys
    a.model_year = nil
    assert_same_contents [:make], a.characteristics.relevant.keys
    a.model_year = 1999
    assert_same_contents [:make, :model_year, :model, :variant], a.characteristics.relevant.keys
    a.model = nil
    assert_same_contents [:make, :model_year], a.characteristics.relevant.keys
    a.model = 'Taurus'
    assert_same_contents [:make, :model_year, :model, :variant], a.characteristics.relevant.keys
    a.variant = nil
    assert_same_contents [:make, :model_year, :model], a.characteristics.relevant.keys
  end
  
  should "handle trumping on multiple levels" do
    a = Automobile.new
    a.size_class = 'small' # can be trumped by model
    a.hybridity = 'no' # can be trumped by variant
    a.make = 'Ford'
    a.model_year = 1999
    a.model = 'Taurus'
    a.variant = 'Taurus 1999'
    assert_same_contents [:make, :model_year, :model, :variant], a.characteristics.relevant.keys
    a.variant = nil
    assert_same_contents [:make, :model_year, :model, :hybridity], a.characteristics.relevant.keys
    a.variant = 'Taurus 1999'
    assert_same_contents [:make, :model_year, :model, :variant], a.characteristics.relevant.keys
    a.model = nil # which reveals size class, but also hybridity!
    assert_same_contents [:make, :model_year, :size_class, :hybridity], a.characteristics.relevant.keys
    a.model = 'Taurus'
    assert_same_contents [:make, :model_year, :model, :variant], a.characteristics.relevant.keys
    a.make = nil
    assert_same_contents [:size_class, :hybridity], a.characteristics.relevant.keys
  end
end
