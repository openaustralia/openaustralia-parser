# Patch a string using another string. Just a wrapper around the diff command

require 'tempfile'

module Patch
  def self.patch(original_text, patch_text)
    # Write the text to a temporary file. Keeping it open so that it doesn't get deleted
    original = Tempfile.new('patch')
    original << original_text
    original.flush

    patch = Tempfile.new('patch')
    patch << patch_text
    patch.flush
    
    system("patch #{original.path} < #{patch.path}")
    raise "Patch failed" unless $? == 0
    original.open.readlines.join
  end
end
