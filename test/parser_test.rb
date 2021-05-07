require 'test_helper'

class StreamParserTest < ActiveSupport::TestCase

  class TestParser
    include StreamParser
  end

  test '#scan_until(STRING)' do
    parser = TestParser.new('abcdefg')
    
    assert parser.scan_until('c').is_a?(MatchData)
    assert_equal 'ab',  parser.pre_match
    assert_equal 'c',   parser.match
    assert_equal 'd',   parser.next_char
    assert_equal false, parser.eos?
    assert_equal 'abcdefg',    parser.current_line
    assert_equal <<-DOC.rstrip,    parser.cursor
   1: abcdefg
      --^
    DOC
    parser.scan_until('f')
    assert_equal 'f',   parser.match
    assert_equal 'g',   parser.next_char
    assert_equal false, parser.eos?
    parser.scan_until('g')
    assert_equal 'g',   parser.match
    assert_nil          parser.next_char
    assert_equal true,  parser.eos?
  end

  test '#scan_until(REGEX)' do
    parser = TestParser.new('abcdefg')
    
    assert parser.scan_until(/g/).is_a?(MatchData)
    assert_equal 'abcdef',  parser.pre_match
    assert_equal 'g',       parser.match
    assert_nil              parser.next_char
    assert_equal true,      parser.eos?
    assert_equal 'abcdefg', parser.current_line
    assert_equal <<-DOC.rstrip,    parser.cursor
   1: abcdefg
      ------^
    DOC
  end

  test '#cursor examples' do
    parser = TestParser.new('abcdefg')
    assert_equal <<-DOC.rstrip,    parser.cursor
   1: abcdefg
     ^
    DOC

    parser.scan_until(/d/)
    assert_equal <<-DOC.rstrip,    parser.cursor
   1: abcdefg
      ---^
    DOC

    parser.scan_until(/g/)
    assert_equal <<-DOC.rstrip,    parser.cursor
   1: abcdefg
      ------^
    DOC

    parser = TestParser.new(<<-DOC)
module ClassMethods
  def parse(source, *args, **nparams, &block)
    self.new(source).parse(*args, **nparams, &block)
  end
end
DOC
   assert_equal <<-DOC.rstrip,    parser.cursor
   1: module ClassMethods
     ^
DOC

   parser.scan_until('module')
   assert_equal <<-DOC.rstrip,    parser.cursor
   1: module ClassMethods
      ^^^^^^
DOC

    parser.scan_until('Methods')
    assert_equal <<-DOC.rstrip,    parser.cursor
   1: module ClassMethods
      ------------^^^^^^^
 DOC
    
    parser.scan_until('parse')
    assert_equal <<-DOC.rstrip,    parser.cursor
   2:   def parse(source, *args, **nparams, &block)
      ------^^^^^
    DOC

    parser.scan_until(')')
    assert_equal <<-DOC.rstrip,    parser.cursor
   2:   def parse(source, *args, **nparams, &block)
      --------------------------------------------^
    DOC
    
    parser.scan_until('end')
    assert_equal <<-DOC.rstrip,    parser.cursor
   4:   end
      --^^^
    DOC
    
    parser.scan_until('end')
    assert_equal <<-DOC.rstrip,    parser.cursor
   5: end
      ^^^
    DOC
  end

  test '#current_line examples' do
    parser = TestParser.new('abcdefg')
    assert_equal 'abcdefg', parser.current_line
    parser.scan_until('g')
    assert_equal 'abcdefg', parser.current_line
    
    parser = TestParser.new(<<-DOC)
module ClassMethods
  def parse(source, *args, **nparams, &block)
    self.new(source).parse(*args, **nparams, &block)
  end
end
DOC

    assert_equal 'module ClassMethods', parser.current_line

    parser.scan_until('module')
    assert_equal 'module ClassMethods', parser.current_line

    parser.scan_until('Methods')
    assert_equal 'module ClassMethods', parser.current_line
    
    parser.scan_until('parse')
    assert_equal '  def parse(source, *args, **nparams, &block)', parser.current_line

    parser.scan_until(')')
    assert_equal '  def parse(source, *args, **nparams, &block)', parser.current_line
    
    parser.scan_until('end')
    assert_equal '  end', parser.current_line
    
    parser.scan_until('end')
    assert_equal 'end', parser.current_line
  end

  test "#quoted_value examples" do
    parser = TestParser.new(%q("this", "\"is", "a\"", "te\"st", 'to', '\'see', 'quotes\'', 'wo\'rk'))
    
    parser.scan_until('"')
    assert_equal 'this', parser.quoted_value('"')
    
    parser.scan_until('"')
    assert_equal '"is', parser.quoted_value('"')

    parser.scan_until('"')
    assert_equal 'a"', parser.quoted_value('"')

    parser.scan_until('"')
    assert_equal 'te"st', parser.quoted_value('"')
    
    parser.scan_until("'")
    assert_equal "to", parser.quoted_value("'")
    
    parser.scan_until("'")
    assert_equal "'see", parser.quoted_value("'")
    parser.scan_until("'")
    
    assert_equal "quotes'", parser.quoted_value("'")
    
    parser.scan_until("'")
    assert_equal "wo'rk", parser.quoted_value("'")
  end
end