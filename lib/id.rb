# Generates unique identifier for each piece of text in the Hansard
class Id
  def initialize(prefix, start_count = 1)
    @prefix = prefix
    @count = start_count - 1
  end
  
  def to_s
    @count = @count + 1
 	  "#{@prefix}#{@count}"
  end
end
