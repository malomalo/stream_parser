module StreamParser

  autoload :HTML, 'stream_parser/html'
  autoload :SyntaxError, 'stream_parser/syntax_error'
  
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    
    def parse(source, *args, **nparams, &block)
      self.new(source).parse(*args, **nparams, &block)
    end
    
  end

  attr_accessor :match
  
  def initialize(source)
    @source = source
    seek(0)
  end
  
  # def parse
  #   # implmentation
  # end

  def eos?
    @index >= (@source.size - 0)
  end

  def scan_until(r)
    r = Regexp.new(Regexp.escape(r)) if r.is_a?(String)
    match = @source.match(r, @index)
    index = match&.begin(0)
    
    if match
      @match = match.to_s
      @old_index = @index
      @index = index + @match.size
    else
      @match = nil
      @old_index = @index
      @index = @source.size
    end
    match
  end
  
  def gobble(r)
    m = @source.match(r, @index)
    if m&.begin(0) == @index
      scan_until(r)
    end
  end

  def pre_match
    @source[@old_index...(@index-(@match&.size || 0))]
  end

  def rewind(by=1)
    @index -= by
  end

  def forward(by=1)
    @index += by
  end

  def seek(pos)
    @old_index = nil
    @match = nil
    @index = pos
  end

  def next_char
    @source[@index]
  end
  
  def prev_char
    @source[@index-1]
  end
  
  def next?(r)
    @source.match(r, @index)&.begin(0) == @index
  end

  def peek(n=1)
    if n.is_a?(Regexp)
      @source.match(n, @index)
    else
      @source.slice(@index, n)
    end
  end

  def next_word
    nw = @source.match(/\s*(\S+)/, @index)
    nw.nil? ? nil : nw[1]
  end

  def current_line
    start = @source.rindex(/(\n|\A)/, @index-(@match&.length||0)) || 0
    start += 1 if @source[start] == "\n"

    uptop = @source.index(/(\n|\z)/, @index)
    uptop -= 1 if @source[uptop] == "\n"

    @source[start..uptop]
  end

  def cursor
    start = @source.rindex(/(\n|\A)/, @index-(@match&.length||0)) || 0
    start += 1 if @source[start] == "\n"

    uptop = @source.index(/(\n|\z)/, @index)
    uptop -= 1 if @source[uptop] == "\n"

    lineno = @source[0..start].count("\n") + 1

    output =  "#{lineno.to_s.rjust(4)}: #{@source[start..uptop]}\n     "
    output << if @match
      " #{'-'* (@index-(@match.length)-start)}#{'^'*(@match.length)}"
    else
      "^"
    end
    output
  end

  def quoted_value(quote_char = '"', escape_chars = ["\\"])
    ret_value = ""
    while scan_until(/(#{quote_char}|\Z)/)
      if match != quote_char
        raise StreamParser::SyntaxError.new("Unbalanced quotes #{quote_char}")
      elsif !escape_chars.include?(pre_match[-1])
        ret_value << pre_match
        return ret_value
      else
        ret_value << pre_match[0...-1] << match
      end
    end
  end
  
end