# Patch a string using another string. Just a wrapper around the diff command

require 'tempfile'

module Patch
  def self.patch(text, patch)
    # Write the text to a temporary file
    f = Tempfile.new('patch')
    f << text
    f.flush

    IO.popen("patch #{f.path}", "w") do |p|
      p << patch
    end
    f.open.readlines.join
  end
end
