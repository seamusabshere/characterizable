require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'ruby-debug'
require 'set'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'characterizable'

class Test::Unit::TestCase
  def assert_same_contents(a, b)
    assert_equal Set.new(a), Set.new(b)
  end
end
