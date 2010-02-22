require 'test/unit'

#this is for test purposes - pretend this is the real class
class Driver

  attr_accessor :age, :name
  def location
    puts "this is a test"
  end

end

#and this is the class that is "duck type" equivalent
class AnotherDriver
  attr_accessor :age, :name, :location
  attr_reader :irrelevant

end

class NotADriver
  attr_accessor :name, :age
end


class FactTest < Test::Unit::TestCase

  def test_match
    fields = ["age", "name", "location"]

    obj = Driver.new



    #is_a = true
    #fields.each{ |field| if not obj.respond_to? field then is_a = false end }
    #assert is_a
    assert(check(fields, Driver.new))
    assert(check(fields, NotADriver.new) == false)
    assert(check(fields, AnotherDriver.new))

  end

  #check if a object conforms to a field list
  #to help work out what its head template is
  def check fields, obj
    fields.each{ |field|
      if not obj.respond_to? field then
        return false
      end
    }
    return true
  end

end
