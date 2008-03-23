# Generates unique identifier for each piece of text in the Hansard
class Id
  def initialize(prefix, count = 1)
    @prefix = prefix
    @count = count
  end
  
  def to_s
 	  "#{@prefix}#{@count}"
  end
  
  def inspect
    to_s
  end
  
  def next
    @count = @count + 1
  end
end
