# frozen_string_literal: true

class StreamParser::HTML::Tag
  # Elements that never have a closing tag, see
  # https://html.spec.whatwg.org/multipage/syntax.html#void-elements
  VOID_ELEMENTS = %w(area base br col embed hr img input link meta source track wbr).freeze

  attr_reader :name, :attributes
  attr_writer :self_closing
  
  def initialize(name, closing=false)
    @name = name
    @attributes = {}
    @closing = closing
    @self_closing = false
  end

  def [](key)
    @attributes[key.to_sym]
  end

  def []=(key, value)
    @attributes[key.to_sym] = value
  end
  
  def self_closing?
    @self_closing
  end
  
  def closing?
    @closing
  end
  
  def opening?
    !@closing
  end

  def void?
    VOID_ELEMENTS.include?(@name&.downcase)
  end
  
  def match(name: nil, closing: nil, attributes: nil)
    return false if name && @name != name
    return false if !closing.nil? && @closing != closing
    return false if attributes && !attributes.all? { |k,v| @attributes[k] == v }
    
    true
  end
end