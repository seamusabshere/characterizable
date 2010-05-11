require 'helper'

# TODO
# class Automobile
#   characterize do
#     has :make do |make|
#       make.reveals :model_year do |model_year|
#         model_year.reveals :model, :trumps => :size_class do |model|
#           model.reveals :variant, :trumps => :hybridity
#         end
#       end
#     end
#     has :size_class
#     has :fuel_type
#     has :fuel_efficiency, :trumps => [:urbanity, :hybridity], :measures => :length_per_volume
#     has :urbanity, :measures => :percentage
#     has :hybridity
#     has :daily_distance_estimate, :trumps => [:weekly_distance_estimate, :annual_distance_estimate, :daily_duration], :measures => :length #, :weekly_fuel_cost, :annual_fuel_cost]
#     has :daily_duration, :trumps => [:annual_distance_estimate, :weekly_distance_estimate, :daily_distance_estimate], :measures => :time #, :weekly_fuel_cost, :annual_fuel_cost]
#     has :weekly_distance_estimate, :trumps => [:annual_distance_estimate, :daily_distance_estimate, :daily_duration], :measures => :length #, :weekly_fuel_cost, :annual_fuel_cost]
#     has :annual_distance_estimate, :trumps => [:weekly_distance_estimate, :daily_distance_estimate, :daily_duration], :measures => :length #, :weekly_fuel_cost, :annual_fuel_cost]
#     has :acquisition
#     has :retirement
#   end
# end

class SimpleAutomobile
  include Characterizable
  attr_accessor :make
  attr_accessor :model
  characterize do
    has :make
    has :model
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
    assert_equal [:make], a.known_characteristics
  end
  
  should "tell you what characteristics are unknown" do
    a = SimpleAutomobile.new
    a.make = 'Ford'
    assert_equal [:model], a.unknown_characteristics
  end
end
