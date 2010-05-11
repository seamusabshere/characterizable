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

  should "tell you what characteristics are known" do
    a = SimpleAutomobile.new
    a.make = 'Ford'
    assert_equal [:make], a.known_characteristics.map(&:name)
  end

  should "tell you what characteristics are unknown" do
    a = SimpleAutomobile.new
    a.make = 'Ford'
    assert_equal [:model, :variant], a.unknown_characteristics.map(&:name)
  end

  should "present a concise set of known characteristics by getting rid of those that have been trumped" do
    a = SimpleAutomobile.new
    a.make = 'Ford'
    a.model = 'Taurus'
    a.variant = 'Taurus V6 DOHC'
    assert_equal [:make, :variant], a.known_characteristics.map(&:name)
  end

  should "not mention a characteristic as unknown if, in fact, it has been trumped" do
    a = SimpleAutomobile.new
    a.make = 'Ford'
    a.variant = 'Taurus V6 DOHC'
    assert_equal [], a.unknown_characteristics.map(&:name)
  end

  should "not mention a characteristic as unknown if it is waiting on something else to be revealed" do
    a = Automobile.new
    assert !a.unknown_characteristics.map(&:name).include?(:model_year)
  end

  should "make sure that trumping works even within revealed characteristics" do
    a = Automobile.new
    assert a.unknown_characteristics.map(&:name).include?(:size_class)
    a.make = 'Ford'
    a.model_year = 1999
    a.model = 'Taurus'
    a.size_class = 'mid-size'
    assert_equal [:model, :model_year, :make], a.known_characteristics.map(&:name)
    assert !a.unknown_characteristics.map(&:name).include?(:size_class)
  end

  should "not enforce prerequisites by using an object's setter" do
    a = Automobile.new
    a.make = 'Ford'
    a.model_year = 1999
    a.make = nil
    assert_equal 1999, a.model_year
    assert !a.known_characteristics.map(&:value).include?(1999)
  end
  
  should "keep user-defined options on a characteristic" do
    assert_equal :length, Automobile.characteristics[:daily_distance_estimate].options[:measures]
  end
  
  should "not confuse user-defined options with other options" do
    assert !Automobile.characteristics[:daily_distance_estimate].options.has_key?(:trumps)
  end
  
  should "know which characteristics are 'visible'" do
    a = Automobile.new
    assert a.unknown_characteristics.map(&:name).include?(:record_creation_date)
    assert !a.visible_unknown_characteristics.map(&:name).include?(:record_creation_date)
    a.record_creation_date = 'yesterday'
    assert a.known_characteristics.map(&:name).include?(:record_creation_date)
    assert !a.visible_known_characteristics.map(&:name).include?(:record_creation_date)
  end
  
  should "be able to access values" do
    a = Automobile.new
    a.make = 'Ford'
    b = Automobile.new
    b.make = 'Pontiac'
    assert_equal 'Ford', Automobile.characteristics[:make].value(a)
    assert_equal 'Pontiac', Automobile.characteristics[:make].value(b)
  end
  
  should "give back characteristics with values when accessed from an instance" do
    a = Automobile.new
    a.make = 'Ford'
    assert_equal 'Ford', a.characteristics[:make].value
  end
  
  should "not allow treating [unbound] characteristics like bound ones" do
    a = Automobile.new
    a.make = 'Ford'
    assert_raises(Characterizable::Characteristic::TreatedUnboundAsBound) do
      Automobile.characteristics[:make].value
    end
  end
  
  should "not allow treating bound characteristics like unbound ones" do
    a = Automobile.new
    a.make = 'Ford'
    b = Automobile.new
    b.make = 'Pontiac'
    assert_raises(Characterizable::Characteristic::TreatedBoundAsUnbound) do
      a.characteristics[:make].value :anything
    end
  end
  
  should "eagely populate bound characteristics" do
    a = Automobile.new
    a.make = 'Ford'
    assert_equal ['Ford'], a.known_characteristics.map(&:value)
    assert_equal [:make], a.known_characteristics.map(&:name)
  end
end
