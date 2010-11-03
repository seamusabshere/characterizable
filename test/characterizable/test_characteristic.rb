require 'helper'

class Character
  include Characterizable
end

class Characterizable::CharacteristicTest < Test::Unit::TestCase
  context 'display' do
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
end
