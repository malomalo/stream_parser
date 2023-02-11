module StreamParser::HTML
  
  autoload :Tag, File.expand_path('../html/tag', __FILE__)
  
  def self.included(base)
    base.include(StreamParser)
  end
  
  def next_tag(old_index: nil)
    old_index ||= @index
    return unless scan_until(/<\s*/)
    start_index = @index-1

    while peek(3) == '!--'
      forward(3)
      scan_until(/-->\s*/)
      scan_until(/<\s*/)
    end
    
    # HTMLComment.new(pre_match)
    if peek(1) == '/'
      scan_until(/[^>\s\/]+/)
      scan_tag(match, old_index: old_index, start_index: start_index, closing: true)
    else
      scan_until(/[^>\s\/]+/)
      scan_tag(match, old_index: old_index, start_index: start_index) 
    end
  end
  
  def scan_for_tag(name, closing: nil, **attributes)
    old_index ||= @index
    tag = next_tag
    while tag && !tag.match(name: name, closing: closing, attributes: attributes)
      tag = next_tag(old_index: old_index)
    end
    tag
  end
  
  def scan_for_closing_tag
    old_index = @index
    heap = []
    
    tag = next_tag
    puts tag.inspect
    while tag && !(tag.closing? && heap.empty?)
      if !tag.closing? && !tag.self_closing?
        heap << tag
      elsif !tag.self_closing?
        heap.pop
      end
      tag = next_tag(old_index: old_index)
    end
    @old_index = old_index
    tag
  end
  
  def scan_tag(name, closing: false, old_index:, start_index:)
    tag = Tag.new(name, closing)
    
    while !eos?
      gobble(/\s+/)
      key = case peek(1)
      when '>'
        forward(1)
        @old_index = old_index
        @match = @source[start_index...@index]
        return tag
      when '/'
        forward(1)
        gobble(/\s*\>/)
        @old_index = old_index
        @match = @source[start_index...@index]
        tag.self_closing = true
        return tag
      when '"', "'"
        quote_char = next_char
        forward(1)
        quoted_value(quote_char)
      else
        scan_until(/[^>\s\/=]+/)[0]
      end
      
      tag[key] = if next?(/\s*=/)
        gobble(/\s*=/)
        html_tag_value
      else
        true
      end
    end

    @old_index = old_index
    @match = @source[start_index...@index]
    tag
  end
  
  def html_tag_value
    gobble(/\s+/)
    case peek(1)
    when '"', "'"
      quote_char = next_char
      forward(1)
      quoted_value(quote_char)
    else
      scan_until(/[^>\s\/=]+/)[0]
    end
  end
  
  def next_end_tag(name)
    scan_until(/<\/\s*li>/)
  end
  
end