# frozen_string_literal: true

# Patch a string using another string. Just a wrapper around the patch command

require "tempfile"

module Patch
  def self.patch(original_text, patch_text)
    # Write the text to a temporary file. Keeping it open so that it doesn't get deleted
    original = Tempfile.new("patch")
    original << original_text
    original.flush

    patch = Tempfile.new("patch")
    patch << patch_text
    patch.flush

    # Upstream sometimes fixes the source text itself, leaving our patch already applied
    return original_text if !applies?(original.path, patch.path) && applies?(original.path, patch.path, reverse: true)

    raise "Patch failed" unless run(original.path, patch.path)

    original.open.readlines.join
  end

  # --batch stops patch asking questions on /dev/tty and hanging; --forward stops it assuming -R for a patch that looks already applied
  def self.run(original_path, patch_path, options: [], quiet: false)
    system("patch", "--batch", "--forward", "--quiet", *options, original_path, in: patch_path, **(quiet ? { out: File::NULL, err: File::NULL } : {}))
  end

  def self.applies?(original_path, patch_path, reverse: false)
    options = reverse ? ["--dry-run", "--reverse"] : ["--dry-run"]
    run(original_path, patch_path, options: options, quiet: true)
  end

  private_class_method :run, :applies?
end
