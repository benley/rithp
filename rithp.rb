#!/usr/bin/env ruby

require 'continuation'

# Rithp
class Env < Hash
  def initialize(keys = [], vals = [], outer = nil)
    @outer = outer
    keys.zip(vals).each { |p| store(*p) }
  end

  def [](name)
    super(name) || @outer[name]
  end

  def set(name, value)
    key?(name) ? store(name, value) : @outer.set(name, value)
  end
end

# Rithp
class Rithp
  STR_TAG = '__RUBYSTRING__'

  def initialize(src = '')
    @pp_strings = []
    pp_src = preprocess(src)
    @ast = parse(pp_src)
    @env = add_globals(Env.new)
  end

  def run
    puts(reval(@ast, @env))
  end

  def add_globals(env)
    ops = [:/, :>, :<, :>=, :<=, :==]
    ops.each { |op| env[op] = ->(a, b) { a.send(op, b) } }
    env.update(
      :+ =>    ->(*xs)  { xs.reduce(0, :+) },
      :- =>    ->(*xs)  { xs.reduce(:-) },
      :* =>    ->(*xs)  { xs.reduce(1, :*) },
      append:  ->(x, y) { x + y },
      car:     ->(x)    { x[0] },
      cdr:     ->(x)    { x[1..-1] },
      cons:    ->(x, y) { [x] + y },
      display: ->(x)    { puts x.inspect },
      length:  ->(x)    { x.length },
      list:    ->(*xs)  { xs },
      list?:   ->(x)    { x.is_a? Array },
      not:     ->(x)    { !x },
      null?:   ->(x)    { x.nil? },
      symbol?: ->(x)    { x.is_a? Symbol },
      callcc: lambda do |x|
        func = reval(x, env)
        callcc { |cont| func.call(->(z) { cont.call(z) }) }
      end)
  end

  def reval(x, env)
    return env[x] if x.is_a? Symbol
    return x unless x.is_a? Array
    case x[0]
    when :quote then x[1..-1]
    when :if
      _, test, conseq, alt = x
      reval(reval(test, env) ? conseq : alt, env)
    when :set! then env.set(x[1], reval(x[2], env))
    when :define then env[x[1]] = reval(x[2], env)
    when :lambda
      _, vars, exp = x
      proc { |*args| reval(exp, Env.new(vars, args, env)) }
    when :begin
      x[1..-1].reduce([nil, env]) do
        |val_env, xp| [reval(xp, val_env[1]), val_env[1]]
      end[0]
    else
      exps = x.map { |xp| reval(xp, env) }
      exps[0].call(*exps[1..-1])
    end
  end

  def atom(s)
    return '[' if s == '('
    return ']' if s == ')'
    if s =~ /^-?\d+$/ ||    # integers
       s =~ /^-?\d*\.\d+$/  # decimals
      return s
    end
    ':' + s
  end

  def parse(src)
    tokens = src.gsub('(', ' ( ').gsub(')', ' ) ').split
    ast = tokens.map { |s| atom(s) }
                .join(' ')
                .gsub(' ]', ']')
                .gsub(/([^\[]) /, '\1, ')
                .gsub(":#{STR_TAG}") { |m| @pp_strings.pop.inspect }
    Kernel.eval(ast)
  end

  def preprocess(src)
    # Pull out strings into a ref table, and replace them all with a constant
    # tag that shouldn't otherwise appear in the source. This seems shitty, but
    # it will do for now.
    str_regex = /"((?:\\?.)*?)"/m
    @pp_strings = src.scan(str_regex).flatten.reverse

    src.gsub!(str_regex, STR_TAG)

    # Filter out comments; the parser will never even see them.
    src.split("\n").map { |x| x.gsub(/;.*$/, '') }
       .join(' ')
  end
end

if ARGV.size > 0
  src = open(ARGV[0], 'r') { |f| f.read }
  runner = Rithp.new(src)
  runner.run
else
  puts('usage: rithp.rb file.scm')
end
