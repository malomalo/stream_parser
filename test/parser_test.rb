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

  test '#gobble(STRING)' do
    parser = TestParser.new('a.b.c')

    assert_nil parser.gobble('.')
    assert_equal 'a', parser.next_char

    assert parser.gobble('a.')
    assert_equal 'a.', parser.match
    assert_equal 'b',  parser.next_char
  end

  test '#gobble(REGEX)' do
    parser = TestParser.new('a.b.c')

    assert_nil parser.gobble(/b/)
    assert_equal 'a', parser.next_char

    assert parser.gobble(/./)
    assert_equal 'a', parser.match
    assert_equal '.', parser.next_char
  end

  test '#next?(STRING)' do
    parser = TestParser.new('a.b')

    assert_equal false, parser.next?('.')
    assert_equal true,  parser.next?('a.')
    parser.forward
    assert_equal true,  parser.next?('.')
  end

  test '#next?(REGEX)' do
    parser = TestParser.new('a.b')

    assert_equal true,  parser.next?(/./)
    assert_equal false, parser.next?(/b/)
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
  
  test "#quoted_value unbalanced example" do
    parser = TestParser.new(%q("this))
    
    parser.scan_until('"')
    assert_raises StreamParser::SyntaxError, 'Unbalanced quotes "' do
      parser.quoted_value('"')
    end
  end
  
test 'multibyte characters' do
    parser = TestParser.new("héllo wörld ✓ done")

    assert parser.scan_until('ö')
    assert_equal 'héllo w', parser.pre_match
    assert_equal 'ö',       parser.match
    assert_equal 'r',       parser.next_char
    assert_equal 'ö',       parser.prev_char
    assert_equal 'rld ✓',   parser.peek(5)
    assert_equal 'héllo wörld ✓ done', parser.current_line
    assert_equal <<-DOC.rstrip, parser.cursor
   1: héllo wörld ✓ done
      -------^
    DOC

    assert parser.scan_until(/✓/)
    assert_equal 'rld ', parser.pre_match
    assert_equal 'done', parser.next_word

    parser.rewind(2)
    assert_equal ' ', parser.next_char
    parser.rewind
    assert_equal 'd', parser.next_char
    parser.forward(3)
    assert_equal ' ', parser.next_char
    assert parser.gobble(' ')
    assert_equal true, parser.next?('done')
    assert_equal true, parser.next?(/d/)

    assert parser.scan_until('done')
    assert_equal true, parser.eos?
    assert_nil parser.next_char

    parser.seek(1)
    assert_equal 'é', parser.next_char
    assert_equal 'h', parser.prev_char
    assert parser.scan_until(/\s/)
    assert_equal 'éllo', parser.pre_match
  end

  test '#cursor with multibyte characters on multiple lines' do
    parser = TestParser.new("ünïcode\nlïne twö\n")

    parser.scan_until('twö')
    assert_equal 'lïne twö', parser.current_line
    assert_equal <<-DOC.rstrip, parser.cursor
   2: lïne twö
      -----^^^
    DOC
  end

  test '#quoted_value with multibyte characters' do
    parser = TestParser.new(%q("hé\"llö" 'wörld'))

    parser.scan_until('"')
    assert_equal 'hé"llö', parser.quoted_value('"')
    parser.scan_until("'")
    assert_equal 'wörld', parser.quoted_value("'")
    assert parser.eos?
  end

end