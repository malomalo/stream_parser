class StreamParser::HTML::Tag
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
  
  def match(name: nil, closing: nil, attributes: nil)
    return false if name && @name != name
    return false if !closing.nil? && @closing != closing
    return false if attributes && !attributes.all? { |k,v| @attributes[k] == v }
    
    true
  end
end