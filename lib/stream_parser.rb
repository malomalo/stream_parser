# frozen_string_literal: true

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

  # Enough bytes to hold any single character (CESU-8 uses up to 6)
  MAX_CHAR_BYTES = 6
  
  # @index, @old_index, and the positions used internally are byte offsets
  # into @source so scanning doesn't have to convert between character and
  # byte offsets. The public interface (forward, rewind, seek, peek, ...)
  # counts characters.
  def initialize(source)
    @source = source
    seek(0)
  end
  
  # def parse
  #   # implmentation
  # end

  def eos?
    @index >= @source.bytesize
  end

  def scan_until(r)
    r = Regexp.new(Regexp.escape(r)) if r.is_a?(String)
    match = @source.byteindex(r, @index) && $~
    
    if match
      @match = match.to_s
      @old_index = @index
      @index = match.byteend(0)
    else
      @match = nil
      @old_index = @index
      @index = @source.bytesize
    end
    match
  end
  
  def gobble(r)
    r = Regexp.new(Regexp.escape(r)) if r.is_a?(String)
    if @source.byteindex(r, @index) == @index
      scan_until(r)
    end
  end

  def pre_match
    @source.byteslice(@old_index...(@index - (@match&.bytesize || 0)))
  end

  def rewind(by=1)
    if @source.encoding == Encoding::UTF_8 || @source.ascii_only?
      # Step back over UTF-8 continuation bytes (0b10xxxxxx), so rewinding
      # costs the characters rewound rather than the source before @index
      by.times do
        break if @index == 0
        @index -= 1
        @index -= 1 while @index > 0 && (@source.getbyte(@index) & 0b1100_0000) == 0b1000_0000
      end
    else
      before = @source.byteslice(0, @index)
      @index -= (before[-by..] || before).bytesize
    end
  end

  def forward(by=1)
    @index += peek(by).bytesize
  end

  def seek(pos)
    @old_index = nil
    @match = nil
    @index = @source[0, pos].bytesize
  end

  def next_char
    peek(1)[0]
  end
  
  def prev_char
    @source.byteslice(0, @index)[-1]
  end
  
  def next?(r)
    r = Regexp.new(Regexp.escape(r)) if r.is_a?(String)
    @source.byteindex(r, @index) == @index
  end

  def peek(n=1)
    if n.is_a?(Regexp)
      @source.byteindex(n, @index) && $~
    else
      # Slicing forward from a character boundary always decodes correctly,
      # and n characters fit in n * MAX_CHAR_BYTES bytes
      @source.byteslice(@index, n * MAX_CHAR_BYTES)[0, n]
    end
  end

  def next_word
    @source.byteindex(/\s*(\S+)/, @index) && $~[1]
  end

  def current_line
    start = @source.byterindex(/(\n|\A)/, @index - (@match&.bytesize || 0)) || 0
    start += 1 if @source.getbyte(start) == 10

    uptop = @source.byteindex(/(\n|\z)/, @index)
    uptop -= 1 if @source.getbyte(uptop) == 10

    @source.byteslice(start..uptop)
  end

  def cursor
    start = @source.byterindex(/(\n|\A)/, @index - (@match&.bytesize || 0)) || 0
    start += 1 if @source.getbyte(start) == 10

    uptop = @source.byteindex(/(\n|\z)/, @index)
    uptop -= 1 if @source.getbyte(uptop) == 10

    lineno = @source.byteslice(0, start).count("\n") + 1
    lineno += 1 if @source.getbyte(start) == 10

    output =  "#{lineno.to_s.rjust(4)}: #{@source.byteslice(start..uptop)}\n     "
    output << if @match
      before_match = @source.byteslice(start...(@index - @match.bytesize))
      " #{'-' * before_match.length}#{'^' * @match.length}"
    else
      "^"
    end
    output
  end

  def quoted_value(quote_char = '"', escape_chars = ["\\"])
    ret_value = String.new
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