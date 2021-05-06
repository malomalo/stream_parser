# StreamParser

StreamParser is a Ruby Module to help build fast and efficent parsers.

Installation
------------

Add `gem 'stream_parser'` to your Gemfile or install via RubyGems (`gem install stream_parser`)

Usage Example:
--------------

Below is an example to extract all quoted strings from a string:

```ruby
class QuotedStringFinder
  include StreamParser
  
  def parse
    @stack = []
    @results = []
    
    while !eos?
        case @stack.last
        when :double_quoted_string
            if scan_until('"') # Can only use pre_match is there is a match
              @results << pre_match
              @stack.pop
            end
        when :single_quoted_string
            if scan_until("'") # Can only use pre_match is there is a match
              @results << pre_match
              @stack.pop
            end
        else
            scan_until(/['"]/)
            if match == '"'
              @stack << :double_quoted_string
            elsif match == "'"
              @stack << :single_quoted_string
            end
        end
    end
    
    raise SyntaxError.new("Unbalanced Quotes in string") if !@stack.empty?
    
    @results
  end
end

QuotedStringFinder.parse(%q{Here "are" a few 'examples' for "you"})
# => ["are", "examples", "you"]

QuotedStringFinder.parse(%q{Here "ar})
# => SyntaxError "Unbalanced Quotes in string"
```



