
require 'rules.rb'

class EngineTest < Test::Unit::TestCase

  def test_fail
    #now lets test inference
    wm1 = ["a", "b"]
    wm2 = ["c", "d"]
    wm3 = ["e", "f"]
    stack = [wm1, wm2, wm3]
    inf = Inference.new stack.size
    puts "test method ran"
  end

end