require 'yaml'

test = %q{
ruleset-name: ruleset name here
ruleset:
- rule: Dangerous
  with: Driver d, Vehicle v
  if:
  - d.age < 21
  - v.type == 'fast'
  then:
  - puts 'nah verrily'

- rule: rule name
  with: Person p
  if: condition
  then: action

}

yml = YAML.load(test)

yml["ruleset"].each{ |rule|

  rule["if"].each{ |con| puts "condition is: " + con}
  rule["then"].each{ |con| puts "consequence is: " + con}
  puts rule["with"]


}






model = { "ruleset" =>
            [{"if" => ["condition1", "condition2"], "then" => "action", "rule" => "rule name"},
             {"if" => "condition", "then" => "action", "rule" => "rule name"}],
          "name" => "ruleset name here" }


puts model.to_yaml




