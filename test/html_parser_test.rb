require 'test_helper'

class StreamParser::HTMLTest < ActiveSupport::TestCase

  class TestParser
    include StreamParser::HTML
  end

  test '#next_tag open tags' do
    ['<name>', '<name >', '< name>', '< name >'].each do |str|
      parser = TestParser.new(str)
      tag = parser.next_tag
      assert tag
      assert_equal 'name',  tag.name
      assert_equal false,   tag.self_closing?
      assert_equal false,   tag.closing?
      assert_nil parser.next_tag
    end
  end

  test '#next_tag self closing tags' do
    ['<name/>', '<name/ >', '< name/>', '< name />', '<name />', '< name / >'].each do |str|
      parser = TestParser.new(str)
      tag = parser.next_tag
      assert tag
      assert_equal 'name', tag.name
      assert_equal true, tag.self_closing?
      assert_nil parser.next_tag
    end
  end

  test '#next_tag closing tags' do
    ['</name>', '</ name>', '< /name>', '< / name>'].each do |str|
      parser = TestParser.new(str)
      tag = parser.next_tag
      assert tag
      assert_equal 'name',  tag.name;
      assert_equal false,   tag.self_closing?
      assert_equal true,    tag.closing?
      assert_nil parser.next_tag
    end
  end
  
  test '#next_tag open tag with boolean attributes' do
    ['<name on>', '<name on >'].each do |str|
      parser = TestParser.new(str)
      tag = parser.next_tag
      assert tag
      assert_equal 'name',  tag.name
      assert_equal false,   tag.closing?
      assert_equal false,   tag.self_closing?
      assert_equal({on: true}, tag.attributes)
      assert_nil parser.next_tag
    end
  end
  
  test '#next_tag open tag with mixed attributes' do
    parser = TestParser.new('<article class="post-wrap post-10052"  itemscope  itemtype="http://schema.org/NewsArticle" >')
    tag = parser.next_tag
    assert tag
    assert_equal 'article',  tag.name
    assert_equal false,   tag.closing?
    assert_equal false,   tag.self_closing?
    assert_equal({class: "post-wrap post-10052", itemscope: true, itemtype: "http://schema.org/NewsArticle"}, tag.attributes)
    assert_nil parser.next_tag
  end

  test '#next_tag open tag with attributes' do
    ['<name on=yes>', '<name on= yes >', '<name on =yes >', '<name on = yes >'].each do |str|
      parser = TestParser.new(str)
      tag = parser.next_tag
      assert tag
      assert_equal 'name',  tag.name
      assert_equal false,   tag.closing?
      assert_equal false,   tag.self_closing?
      assert_equal({on: 'yes'}, tag.attributes)
      assert_nil parser.next_tag
    end
  end

  test '#next_tag open tag with unquoted attribute values containing slashes' do
    parser = TestParser.new('<a href=http://example.com/path class=link>text</a>')
    tag = parser.next_tag
    assert_equal 'a', tag.name
    assert_equal false, tag.self_closing?
    assert_equal({href: 'http://example.com/path', class: 'link'}, tag.attributes)
    assert_equal '<a href=http://example.com/path class=link>', parser.match

    tag = parser.next_tag
    assert_equal 'a', tag.name
    assert_equal true, tag.closing?
  end

  test '#next_tag open tag with unquoted attribute values containing equals' do
    parser = TestParser.new('<a href=/search?q=1>')
    tag = parser.next_tag
    assert_equal({href: '/search?q=1'}, tag.attributes)
    assert_nil parser.next_tag
  end

  test '#next_tag open tag with double quoted attribute names' do
    ['<name "on"=yes>', '<name "on"= yes >', '<name "on" =yes >', '<name "on" = yes >'].each do |str|
      parser = TestParser.new(str)
      tag = parser.next_tag
      assert tag
      assert_equal 'name',  tag.name
      assert_equal false,   tag.closing?
      assert_equal false,   tag.self_closing?
      assert_equal({on: 'yes'}, tag.attributes)
      assert_nil parser.next_tag
    end
  end

  test '#next_tag open tag with single quoted attribute names' do
    ["<name 'on'=yes>", "<name 'on'= yes >", "<name 'on' =yes >", "<name 'on' = yes >"].each do |str|
      parser = TestParser.new(str)
      tag = parser.next_tag
      assert tag
      assert_equal 'name',  tag.name
      assert_equal false,   tag.closing?
      assert_equal false,   tag.self_closing?
      assert_equal({on: 'yes'}, tag.attributes)
      assert_nil parser.next_tag
    end
  end

  test '#next_tag open tag with double quoted attribute values' do
    ['<name on="yes">', '<name on= "yes" >', '<name on ="yes" >', '<name on = "yes" >'].each do |str|
      parser = TestParser.new(str)
      tag = parser.next_tag
      assert tag
      assert_equal 'name',  tag.name
      assert_equal false,   tag.closing?
      assert_equal false,   tag.self_closing?
      assert_equal({on: 'yes'}, tag.attributes)
      assert_nil parser.next_tag
    end
  end

  test '#next_tag open tag with single quoted attribute values' do
    ["<name on='yes'>", "<name on= 'yes' >", "<name on ='yes' >", "<name on = 'yes' >"].each do |str|
      parser = TestParser.new(str)
      tag = parser.next_tag
      assert tag
      assert_equal 'name',  tag.name
      assert_equal false,   tag.closing?
      assert_equal false,   tag.self_closing?
      assert_equal({on: 'yes'}, tag.attributes)
      assert_nil parser.next_tag
    end
  end

  test '#next_tag open tag with empty attribute values' do
    ['<name on=><b>', '<name on= ><b>', '<name on = ><b>'].each do |str|
      parser = TestParser.new(str)
      tag = parser.next_tag
      assert_equal 'name',      tag.name
      assert_equal({on: ''},    tag.attributes)
      assert_equal str[0...-3], parser.match

      tag = parser.next_tag
      assert_equal 'b', tag.name
      assert_nil parser.next_tag
    end
  end

  test '#next_tag skipping multiple comments in a row' do
    parser = TestParser.new("<div><!-- ------------------------------------------ --><!-- ------------------------------------------ --></div>")
    tag = parser.next_tag
    assert_equal 'div',  tag.name
    assert_equal false,   tag.closing?
    
    tag = parser.next_tag
    assert_equal 'div',  tag.name
    assert_equal true,   tag.closing?
  end

  test '#next_tag with no tag after a comment' do
    ['<div><!-- x -->', '<div><!-- x --> text', '<div><!-- x'].each do |str|
      parser = TestParser.new(str)
      assert_equal 'div', parser.next_tag.name
      assert_nil parser.next_tag
      assert parser.eos?
    end
  end

  test '#next_tag with input ending inside the tag' do
    {
      '<name '         => {},
      '<name on'       => {on: true},
      '<name on '      => {on: true},
      '<name on ='     => {on: ''},
      '<name on= '     => {on: ''},
      '<name on=yes '  => {on: 'yes'},
      '<name on=yes =' => {on: 'yes'}
    }.each do |str, attributes|
      parser = TestParser.new(str)
      tag = parser.next_tag
      assert_equal 'name',     tag.name
      assert_equal attributes, tag.attributes
      assert_equal str,        parser.match
      assert parser.eos?
      assert_nil parser.next_tag
    end
  end

  test '#scan_for_tag' do
    parser = TestParser.new("<html><div><a></a></div></html>")

    tag = parser.scan_for_tag('div')
    assert_equal 'div',  tag.name
    assert_equal false,   tag.closing?

    tag = parser.scan_for_tag('div')
    assert_equal 'div',  tag.name
    assert_equal true,   tag.closing?

    assert_nil parser.scan_for_tag('div')
  end
  
  test '#scan_for_tag with class' do
    parser = TestParser.new('<html><div><a></a><a class="s"></a><a></a></div></html>')

    tag = parser.scan_for_tag('a', class: 's')
    assert_equal 'a',     tag.name
    assert_equal 's',     tag['class']
    assert_equal false,   tag.closing?

    tag = parser.scan_for_tag('a')
    assert_equal 'a',  tag.name
    assert_equal true,   tag.closing?
  end
  
  test '#scan_for_closing' do
    parser = TestParser.new('<html><div><a></a><a class="s"><span>...</span></a ><a></a></div></html>')

    tag = parser.scan_for_tag('a')
    assert_equal 'a',             tag.name
    assert_equal '<html><div>',   parser.pre_match
    assert_equal '<a>',           parser.match
    
    tag = parser.scan_for_closing_tag
    assert_equal 'a',  tag.name
    assert_equal true, tag.closing?
    assert_equal '',    parser.pre_match
    assert_equal '</a>', parser.match
    
    tag = parser.scan_for_tag('a')
    assert_equal 'a',     tag.name

    tag = parser.scan_for_closing_tag
    assert_equal 'a',  tag.name
    assert_equal true, tag.closing?
    assert_equal '<span>...</span>',    parser.pre_match
    assert_equal '</a >', parser.match
  end
  
  test '#scan_for_closing_tag with enclosed multi-depth tag' do
    parser = TestParser.new(<<~DOC)
    <div class="row"><div> <a > <img src="https://test.com/" /> </a> </div></div>
    DOC
    
    tag = parser.scan_for_tag('div')
    assert_equal 'div',               tag.name
    assert_equal '',                  parser.pre_match
    assert_equal '<div class="row">',           parser.match
    
    tag = parser.scan_for_closing_tag
    assert_equal 'div',  tag.name
    assert_equal true, tag.closing?
    assert_equal '<div> <a > <img src="https://test.com/" /> </a> </div>',    parser.pre_match
    assert_equal '</div>', parser.match
  end

  test '#scan_for_closing_tag with void elements' do
    parser = TestParser.new('<div><br><img src=a.png><BR><p>text</p><hr></div><a></a>')
    parser.scan_for_tag('div')

    tag = parser.scan_for_closing_tag
    assert_equal 'div', tag.name
    assert_equal true,  tag.closing?
    assert_equal '<br><img src=a.png><BR><p>text</p><hr>', parser.pre_match
    assert_equal '</div>', parser.match
  end

  test '#scan_for_closing_tag with mismatched closing tags' do
    # Stray closing tag inside the element is ignored
    parser = TestParser.new('<div><b>x</i></b></div>')
    parser.scan_for_tag('div')
    assert_equal 'div',               parser.scan_for_closing_tag.name
    assert_equal '<b>x</i></b>',      parser.pre_match

    # Closing an outer tag also closes tags left open inside it
    parser = TestParser.new('<div><b><i>x</b></div>')
    parser.scan_for_tag('div')
    assert_equal 'div',               parser.scan_for_closing_tag.name
    assert_equal '<b><i>x</b>',       parser.pre_match
  end

  test '#next_end_tag' do
    parser = TestParser.new('<div><ul><li>one</li></ul></ div ></div>')

    assert parser.next_end_tag('div')
    assert_equal '<div><ul><li>one</li></ul>', parser.pre_match
    assert_equal '</ div >', parser.match

    assert parser.next_end_tag('div')
    assert_equal '</div>', parser.match

    assert_nil parser.next_end_tag('div')
  end

end