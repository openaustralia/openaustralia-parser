# Generates unique identifier for each piece of text in the Hansard
class Id
  def initialize(prefix, start_count = 1)
    @prefix = prefix
    @count = start_count
  end
  
  def to_s
 	  value = "#{@prefix}#{@count}"
    @count = @count + 1
 	  value
  end
end
