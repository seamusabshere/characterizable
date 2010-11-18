require 'helper'

class Character
  include Characterizable
end

class Characterizable::CharacteristicTest < Test::Unit::TestCase
  context Characterizable::Characteristic do
    setup do
      @universe = ComplexAutomobile.new
    end

    context '#display' do
      setup do
        @universe = { :charisma => 'hearty' }
      end

      should 'not display a custom format if display option not given' do
        char = Characterizable::Characteristic.new(Character, :charisma, {})
        assert_nil char.display(@universe)
      end
      should 'display a custom format if display option is given' do
        char = Characterizable::Characteristic.new(Character, :charisma,
                                                   { :display => lambda { |c| "Level: #{c}" } }) {}
        assert_equal 'Level: hearty', char.display(@universe)
      end
    end

    context '#value' do
      context 'universe is a hash' do
        setup do
          @universe = { :daily_duration => 1 }
        end
        should 'return the value for a characteristic' do
          characteristic = Characterizable::Characteristic.new(ComplexAutomobile, :daily_duration, {})
          assert_equal 1, characteristic.value(@universe)
        end
        should 'return nil for a nonexistent characteristic' do
          characteristic = Characterizable::Characteristic.new(ComplexAutomobile, :monthly_duration, {})
          assert_nil characteristic.value(@universe)
        end
      end
      context 'universe is a non-hash' do
        setup do
          @universe.daily_duration = 1
        end
        should 'return the value for a characteristic' do
          characteristic = Characterizable::Characteristic.new(ComplexAutomobile, :daily_duration, {})
          assert_equal 1, characteristic.value(@universe)
        end
        should 'return nil for a nonexistent characteristic' do
          characteristic = Characterizable::Characteristic.new(ComplexAutomobile, :na, {})
          assert_nil characteristic.value(@universe)
        end
      end
    end

    context '#known?' do
      setup do
        @characteristic = @universe.characterizable_base.characteristics[:daily_duration]
      end
      should 'return true if the characteristic is not nil' do
        @universe.daily_duration = 1
        assert @characteristic.known?(@universe)
      end
      should 'return false if the characteristic is nil' do
        assert !@characteristic.known?(@universe)
      end
    end

    context '#revealed?' do
      should 'return true if there are no prerequisites' do
        characteristic = @universe.characterizable_base.characteristics[:size_class]
        assert characteristic.revealed?(@universe)
      end
      should 'return true if its prerequisite is effective' do
        @universe.acquisition = '1'
        characteristic = @universe.characterizable_base.characteristics[:retirement]
        assert characteristic.revealed?(@universe)
      end
      should 'return false if its prerequisite is not effective' do
        characteristic = @universe.characterizable_base.characteristics[:retirement]
        assert !characteristic.revealed?(@universe)
      end
    end

    context '#trumped?' do
      context 'ignoring is empty' do
        should 'return true if trumped by another effective characteristic' do
          @universe.fuel_efficiency = '5'
          char = @universe.characterizable_base.characteristics[:urbanity]
          assert char.trumped?(@universe)
        end
        should 'return false if trumped by another ineffective characteristic' do
          char = @universe.characterizable_base.characteristics[:weekly_distance_estimate]
          assert !char.trumped?(@universe)
        end
        should 'return true if mutually trumped, other is effective, and currently not effective' do
          @universe.daily_distance_estimate = '5'
          char = @universe.characterizable_base.characteristics[:weekly_distance_estimate]
          assert char.trumped?(@universe)
        end
        should 'return false if mutually trumped, other is effective, and currently am effective' do
          @universe.daily_distance_estimate = '5'
          @universe.weekly_distance_estimate = '6'
          char = @universe.characterizable_base.characteristics[:weekly_distance_estimate]
          assert !char.trumped?(@universe)
        end
        should 'return false if mutually trumped, other is not effective' do
          char = @universe.characterizable_base.characteristics[:weekly_distance_estimate]
          assert !char.trumped?(@universe)
        end
      end
      context 'ignoring is set' do
        should 'return false if trumped by another effective characteristic that should be ignored' do
          @universe.daily_distance_estimate = '5'
          char = @universe.characterizable_base.characteristics[:weekly_distance_estimate]
          assert !char.trumped?(@universe, [:daily_distance_estimate])
        end
      end
    end

#    has :daily_distance_estimate, :trumps => [:weekly_distance_estimate, :annual_distance_estimate, :daily_duration], :measures => :length
#    has :daily_duration, :trumps => [:annual_distance_estimate, :weekly_distance_estimate, :daily_distance_estimate], :measures => :time
#    has :weekly_distance_estimate, :trumps => [:annual_distance_estimate, :daily_distance_estimate, :daily_duration], :measures => :length
#    has :annual_distance_estimate, :trumps => [:weekly_distance_estimate, :daily_distance_estimate, :daily_duration], :measures => :length
    context '#effective?' do
      should 'return true if known, revealed, and not trumped' do
        characteristic = @universe.characterizable_base.characteristics[:daily_duration]
        @universe.daily_duration = '1'
        assert characteristic.effective?(@universe)
      end
      should 'return false if known, reavaled, and trumped' do
        @universe.annual_distance_estimate = "33796.2"
        @universe.daily_duration = "3.0"
        char = @universe.characterizable_base.
          characteristics[:daily_duration]
        assert_nothing_raised do
          char.effective?(@universe)
        end
      end
      should 'return false if known, but not revealed' do
        @universe.model_year = '2007'
        char = @universe.characterizable_base.
          characteristics[:model_year]
        assert !char.effective?(@universe)
      end
      should 'return false if not known' do
        char = @universe.characterizable_base.
          characteristics[:model_year]
        assert !char.effective?(@universe)
      end
      should 'not infinitely recurse if there is a 3-way mutual trumping' do
        @universe.annual_distance_estimate = "33796.2"
        @universe.daily_duration = "3.0"
        @universe.weekly_distance_estimate = "804.672"
        char = @universe.characterizable_base.characteristics[:daily_duration]
        assert_nothing_raised do
          char.effective?(@universe)
        end
      end
    end
  end
end
