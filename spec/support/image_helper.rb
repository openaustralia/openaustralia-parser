# frozen_string_literal: true

require "rmagick"

module ImageHelper
  JPEG_MAGIC = "\xFF\xD8\xFF".b

  def valid_jpg?(filename)
    return false if File.binread(filename, 3) != JPEG_MAGIC

    Magick::Image.read(filename).first
    true
  rescue Magick::ImageMagickError
    false
  end
end

RSpec.configure do |config|
  config.include ImageHelper
end
