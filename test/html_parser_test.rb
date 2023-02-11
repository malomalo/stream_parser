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

  test '#next_tag skipping multiple comments in a row' do
    parser = TestParser.new("<div><!-- ------------------------------------------ --><!-- ------------------------------------------ --></div>")
    tag = parser.next_tag
    assert_equal 'div',  tag.name
    assert_equal false,   tag.closing?
    
    tag = parser.next_tag
    assert_equal 'div',  tag.name
    assert_equal true,   tag.closing?
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

end