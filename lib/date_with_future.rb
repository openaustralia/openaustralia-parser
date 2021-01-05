require 'date'

class DateWithFuture < Date
  # Returns a date a long time in the future
  def DateWithFuture.future
    DateWithFuture.new(9999, 12, 31)
  end
end
