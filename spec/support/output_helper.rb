# spec/support/output_helper.rb

module OutputHelper
  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  def capture_stdout_and_stderr
    original_stdout = $stdout
    original_stderr = $stderr
    string_io = StringIO.new
    $stdout = string_io
    $stderr = string_io
    yield
    string_io.string
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end
end

RSpec.configure do |config|
  config.include OutputHelper
end
