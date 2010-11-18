class ComplexAutomobile
  attr_accessor :make, :model_year, :model, :variant
  attr_accessor :fuel_type, :fuel_efficiency, :urbanity
  attr_accessor :hybridity
  attr_accessor :daily_distance_estimate
  attr_accessor :daily_duration
  attr_accessor :weekly_distance_estimate
  attr_accessor :annual_distance_estimate
  attr_accessor :acquisition
  attr_accessor :retirement
  attr_accessor :size_class
  attr_accessor :timeframe
  include Characterizable
  characterize do
    has :make do |make|
      make.reveals :model_year do |model_year|
        model_year.reveals :model, :trumps => :size_class do |model|
          model.reveals :variant, :trumps => :hybridity
        end
      end
    end
    has :fuel_type
    has :fuel_efficiency, :trumps => [:urbanity, :hybridity], :measures => :length_per_volume
    has :urbanity, :measures => :percentage
    has :hybridity
    has :daily_distance_estimate, :trumps => [:weekly_distance_estimate, :annual_distance_estimate, :daily_duration], :measures => :length
    has :daily_duration, :trumps => [:annual_distance_estimate, :weekly_distance_estimate, :daily_distance_estimate], :measures => :time
    has :weekly_distance_estimate, :trumps => [:annual_distance_estimate, :daily_distance_estimate, :daily_duration], :measures => :length
    has :annual_distance_estimate, :trumps => [:weekly_distance_estimate, :daily_distance_estimate, :daily_duration], :measures => :length
    has :acquisition
    has :retirement, :prerequisite => :acquisition
    has :size_class
  end
end

