# Like a Zlib::GzipWriter class but also counts the number of bytes (uncompressed) written out
class SitemapGenerator
  class CountedFile < Zlib::GzipWriter
    attr_reader :size

    def initialize(filename)
      @size = 0
      super
    end

    def <<(text)
      @size += text.size
      super
    end
  end
end
