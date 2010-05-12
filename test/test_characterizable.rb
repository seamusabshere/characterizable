require 'helper'

# TODO
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
    
    assert_equal Characterizable::SurvivorHash, a.characteristics.known.class
    assert_equal Characterizable::SurvivorHash, a.characteristics.known.select { false }.class
    assert_equal Characterizable::SurvivorHash, a.characteristics.known.slice(:hello).class
    assert_equal Characterizable::SurvivorHash, a.characteristics.known.merge({:hi => 'there'}).class

    assert_equal Characterizable::Snapshot, a.characteristics.class
    assert_equal Characterizable::Snapshot, a.characteristics.select { false }.class
    assert_equal Characterizable::Snapshot, a.characteristics.slice(:hello).class
    assert_equal Characterizable::Snapshot, a.characteristics.merge({:hi => 'there'}).class
  end
  
  should "tell you what characteristics are known" do
    a = SimpleAutomobile.new
    a.make = 'Ford'
    assert_equal [:make], a.characteristics.known.keys
  end

  should "tell you what characteristics are unknown" do
    a = SimpleAutomobile.new
    a.make = 'Ford'
    assert_equal [:model, :variant], a.characteristics.unknown.keys
  end

  should "present a concise set of known characteristics by getting rid of those that have been trumped" do
    a = SimpleAutomobile.new
    a.make = 'Ford'
    a.model = 'Taurus'
    a.variant = 'Taurus V6 DOHC'
    assert_equal [:make, :variant], a.characteristics.known.keys
  end

  should "not mention a characteristic as unknown if, in fact, it has been trumped" do
    a = SimpleAutomobile.new
    a.make = 'Ford'
    a.variant = 'Taurus V6 DOHC'
    assert_equal [], a.characteristics.unknown.keys
  end

  should "not mention a characteristic as unknown if it is waiting on something else to be revealed" do
    a = Automobile.new
    assert !a.characteristics.unknown.keys.include?(:model_year)
  end

  should "make sure that trumping works even within revealed characteristics" do
    a = Automobile.new
    assert a.characteristics.unknown.keys.include?(:size_class)
    a.make = 'Ford'
    a.model_year = 1999
    a.model = 'Taurus'
    a.size_class = 'mid-size'
    assert_equal [:make, :model_year, :model], a.characteristics.known.keys
    assert !a.characteristics.unknown.keys.include?(:size_class)
  end

  should "not enforce prerequisites by using an object's setter" do
    a = Automobile.new
    a.make = 'Ford'
    a.model_year = 1999
    a.make = nil
    assert_equal 1999, a.model_year
    assert_equal nil, a.characteristics.known[:model_year]
  end
  
  should "keep user-defined options on a characteristic" do
    assert_equal :length, Automobile.characteristics[:daily_distance_estimate].options[:measures]
  end
  
  should "not confuse user-defined options with other options" do
    assert !Automobile.characteristics[:daily_distance_estimate].options.has_key?(:trumps)
  end
  
  should "know which characteristics are 'visible'" do
    a = Automobile.new
    assert a.characteristics.unknown.keys.include?(:record_creation_date)
    assert !a.characteristics.visible_unknown.keys.include?(:record_creation_date)
    a.record_creation_date = 'yesterday'
    assert a.characteristics.known.keys.include?(:record_creation_date)
    assert !a.characteristics.visible_known.keys.include?(:record_creation_date)
  end
    
  should "be able to access values" do
    a = Automobile.new
    a.make = 'Ford'
    assert_equal 'Ford', a.characteristics[:make]
  end
  
  should "know what is known on a snapshot" do
    a = Automobile.new
    a.make = 'Ford'
    assert_equal [:make], a.characteristics.known.keys
  end
  
  should "know what is unknown on a snapshot" do
    a = Automobile.new
    a.make = 'Ford'
    assert a.characteristics.unknown.keys.include?(:model_year)
  end
  
  should "not reveal unknown characteristics in snapshots" do
    a = Automobile.new
    a.model_year = 1999
    assert_equal [], a.characteristics.known.keys
    assert_equal nil, a.characteristics[:model_year]
  end
  
  should "not reveal unknown characteristics in snapshots, even if it was previously revealed" do
    a = Automobile.new
    a.make = 'Ford'
    a.model_year = 1999
    assert_equal [:make, :model_year], a.characteristics.known.keys
    a.make = nil
    assert_equal [], a.characteristics.known.keys
  end
  
  should "keep snapshots separately" do
    a = Automobile.new
    a.make = 'Ford'
    a.model_year = 1999
    snapshot = a.characteristics
    assert_equal [:make, :model_year], snapshot.known.keys
    a.make = nil
    assert_equal [], a.characteristics.known.keys
    assert_equal [:make, :model_year], snapshot.known.keys
  end
    
  should "work when passed around as a snapshot" do
    a = Automobile.new
    a.make = 'Ford'
    snapshot = a.characteristics
    assert_equal [:make], snapshot.known.keys
    assert snapshot.unknown.keys.include?(:model_year)
    snapshot[:model_year] = 1999
    assert_equal 1999, snapshot[:model_year]
    assert_equal [:make, :model_year], snapshot.known.keys
    assert !snapshot.unknown.keys.include?(:model_year)
    assert_equal nil, a.model_year
    assert_equal nil, a.characteristics[:model_year]
    assert_equal 1999, snapshot[:model_year]
  end
end
