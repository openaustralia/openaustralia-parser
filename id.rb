# Generates unique identifier for each piece of text in the Hansard
class Id
  def initialize(prefix)
    @prefix = prefix
    @count = 0
  end
  
  def to_s
    @count = @count + 1
 	  "#{@prefix}#{@count}"
  end
end
