


#contains a combination of facts to suit a rule (only the "head"/type is checked, no the actual conditions).
class Tuple
    attr_accessor :facts

    def initialize
      @facts = []
    end
end



#this class inferences facts from a stack of like fact lists, and evaluates the rule that is provided
class Inference
  attr_reader :list_of
  attr_reader :rule

  #pass in the stack size, which is the number of lists that will be used for inferencing for the rule
  #thus one instance can be used across rules, as long as they take the same parameters
  def initialize stack_size
    s = make_permutations(stack_size-1)
    self.instance_eval "def process \n" + s + "\nend"
  end

  #pass in a rule, and the stack of fact lists that match the parameter types (heads) for the rule
  #the fact_stack size must be the same as what was initialized, and obviously be stuitable for the rule
  def go rule, fact_stack
    @list_of = fact_stack
    @rule = rule

    process #this method's content is dynamically generated

    @rule = nil
    @list_of = nil
  end

 #this will be called back by the generated method
  def handle tuple

    rule.do_tuple tuple
  end

  #generate a method to come up with tuples, and invoke them
  def make_permutations num_heads
    tupcalc = ""
    for i in 0..num_heads
        tupcalc += " list_of[#{i}].each { |list#{i}| \n"
    end
    tupcalc += " tuple = Tuple.new \n"
    for i in 0..num_heads
        tupcalc += " tuple.facts << list#{i}\n"
      end
    tupcalc += " handle tuple\n"
    for i in 0..num_heads
        tupcalc += " }\n"
    end
    return tupcalc
  end

end

class MockRule
  attr_accessor :count

  def initialize
    @count = 0
  end

  def do_tuple tuple
    @count = @count + 1
    #tuple.facts.each{ |fact|  fact }
  end

end


#now lets test inference
wm1 = ["a", "b"]
wm2 = ["c", "d"]
wm3 = ["e", "f"]
stack = [wm1, wm2, wm3]

inf = Inference.new stack.size
rule = MockRule.new
inf.go rule, stack
puts "PASSED" unless rule.count != 8



#represents a rule., well duh. Can be reused for different tuples. When initialised, builds the code needed for the rule as class methods
class Rule

  attr_accessor :types
  attr_reader :name
  attr_accessor :rule_base

  def initialize params
    config params[:declarations], params[:types], params[:condition], params[:action]
    @name = params[:name]

  end

  #declaration map is the map from var name, in rule, to its type
  def config declarations, types, condition_script, action_script
    if declarations == nil then declarations = [] end
    #may need to build node types for conditions, rather then stuffing it in a script, do some optimisation on the way to RETE
    build_method("condition", declarations, condition_script)
    build_method("action", declarations, action_script)

    #invokers connect tuple with generated methods.
    build_invoker("is_allowed", declarations.size-1, "condition")
    build_invoker("do_action", declarations.size-1, "action")
    if types == nil then types = [] end
    @types = types
  end

  #this is the call back from the inference engine
  def do_tuple tuple
    if is_allowed tuple then
      do_action tuple
    end #maybe slap an else in here? yeah, after I add some proper unit tests
  end

  #builds the invoker for the tuple
  def build_invoker method_name, num_of_args, target_method
    method = "def " + method_name + " t\n"
    method += " " + target_method + " "

    #now build args
    for i in 0..num_of_args
      method += "t.facts[#{i}]"
      method += ", " unless i == num_of_args
    end

    method += "\nend\n"
    #puts "Generating invoker: \n" + method
    instance_eval method
  end

  #this is for handling globals of various sorts
  def method_missing sym, *args
    rule_base.call_global sym, *args
  end

  #populates method guts and adds it to a class instance
  def build_method meth_name, declarations, guts
    method = "def " + meth_name + " "


    decs = declarations
    for i in 0..(decs.size-1)
      method += decs[i]
      method += "," unless i == (decs.size-1)
    end

    method += "\n" + guts
    method += "\nend\n"
    #puts "Generating method: \n" + method
    instance_eval method
  end

end

#now lets  try it out
rule = Rule.new :declarations => ["a", "b"],
                :types => [String.class, String.class],
                :condition =>"a == '42' and b == '42'",
                :action => "puts 'PASSED RULE 1'"

test_tup = Tuple.new
test_tup.facts << '42'
test_tup.facts << '42'

rule.do_tuple test_tup

rule = Rule.new :declarations => ["a", "b"],
                :types => [String.class, String.class],
                :condition =>"b != '42'",
                :action => "puts 'FAILED RULE 2'"
rule.do_tuple test_tup

rule = Rule.new :declarations => ["a", "b"],
                :types => [String.class, String.class],
                :condition => "b == '42'",
                :action=>"puts 'PASSED RULE 3'"
rule.do_tuple test_tup



#now time to do working memory
class WorkingMemory
  attr_accessor :facts
  attr_accessor :rules

  def initialize rule_list
    #map of fact heads to lists (ie each fact type has a list, keyed on the fact type)
    @facts = Hash.new
    @rules = rule_list
  end

  def assert fact
    if @facts.has_key? fact.class then
      existing = @facts[fact.class]
      if not existing.include? fact then
        existing << fact
      end
    else
      @facts[fact.class] = [fact]
    end
  end

  #todo: if we want to use something other then class to be the "head"
  #will need to change assert and fire_all* methods to key it on something else
  #perhaps check for a method existence

  def fire_all_rules
    rules.each { |rule|
      #puts rule.types.size
      stack_of_facts = []
      rule.types.each { |type|
        stack_of_facts << facts[type]
      }
      inf = Inference.new stack_of_facts.size
      inf.go rule, stack_of_facts
    }
  end

end

class RuleBase
  attr_reader :rules

  def initialize
    @rules = []
    @globals = {}
    @functions = {}
  end

  def add_rule rule
    rule.rule_base = self
    @rules << rule
  end

  #
  # Globals are global variables, that can be used in a rule.
  # They are named. You can use them instead of facts if you want named facts.
  # and all the rules can refer to the globals by name. In this
  # case the engine is not really inferencing.
  #
  def add_global name, variable
    @globals[name.intern] = variable
  end

  #adds a function. pass in a method instance or proc
  def add_function name, block
    @functions[name.intern] = block
  end

  #this will add the method content (string) to each rule in the rulebase
  def add_rule_method content
    @rules.each{ |rule|
      rule.instance_eval content
    }
  end

  #creates a brand new empty working memory
  def new_working_memory
    WorkingMemory.new @rules
  end

  #call back for globals and functions, internal use only.
  def call_global sym, *args
    if args.length == 0 then
      @globals[sym]
    else
      #todo: make this work with more then just one function...
      @functions[sym].call(args[0])
    end
  end

end


rb = RuleBase.new
rb.add_rule(Rule.new(     :declarations => ["a","b"],
                          :types => [String, String],
                          :condition => "a == 'hello'",
                          :action => "puts b")
               )

rb.add_rule(Rule.new(     :declarations => ["a"],
                          :types => [String],
                          :condition => "a == 'hello'",
                          :action => "puts 'boo ya global ' + globule; foo 'la' ",
                          :name => "boo")
               )

#this is how to do globals, and functions
rb.add_global "globule", "42"
def foo arg
  puts "called function with arg " + arg
end
rb.add_function "foo", Proc.new{ |m| foo m }

engine = rb.new_working_memory
engine.assert "hello"
engine.assert "world"
engine.fire_all_rules

rb = RuleBase.new
rb.add_rule(Rule.new( :condition=> "q == 42", :action=>'puts "it worked"' ))
rb.add_global "q", 42

engine = rb.new_working_memory
engine.fire_all_rules



