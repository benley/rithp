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

def add_globals(env)
  ops = [:*, :/, :>, :<, :>=, :<=, :==]
  ops.each { |op| env[op] = ->(a, b) { a.send(op, b) } }
  env.update(
    :+ =>    ->(*xs)  { xs.reduce(0, :+) },
    :- =>    ->(*xs)  { xs.reduce(0, :-) },
    append:  ->(x, y) { x + y },
    car:     ->(x)    { x[0] },
    cdr:     ->(x)    { x[1..-1] },
    cons:    ->(x, y) { [x] + y },
    display: ->(x)    { p x },
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
  if s =~ /^".*"$/ ||
     s =~ /^-?\d+$/ ||
     s =~ /^-?\d*\.\d+$/
    return s
  end
  ':' + s
end

def parse(src)
  # This is too simplistic; can't handle strings with spaces.
  # Need to use StringScanner.
  tokens = src.gsub('(', ' ( ').gsub(')', ' ) ').split
  ast = tokens.map { |s| atom(s) }
              .join(' ')
              .gsub(' ]', ']')
              .gsub(/([^\[]) /, '\1, ')
  Kernel.eval(ast)
end

def preprocess(src)
  # Filter out comments; the parser will never even see them.
  # Oh blah, this will eat semicolons inside quoted strings.
  src.split("\n").map { |x| x.gsub(/;.*$/, '') }
     .join(' ')
end

if ARGV.size > 0
  src = open(ARGV[0], 'r') { |f| f.read }
  puts(reval(parse(preprocess(src)), add_globals(Env.new)))
else
  puts('usage: rithp.rb file.scm')
end
