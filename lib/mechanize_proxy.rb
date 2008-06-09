# Very stripped down proxy for WWW::Mechanize
#
# Stores cached html files in directory "html_cache_path" in configuration.yml

require 'rubygems'
gem 'mechanize', "= 0.6.10"
require 'mechanize'
require 'configuration'

class MechanizeProxy
  # By setting cache_subdirectory can put cached files under a subdirectory in the html_cache_path
  attr_accessor :cache_subdirectory
  
  def initialize
    @agent = WWW::Mechanize.new
    @conf = Configuration.new
  end
  
  def get(url)
    uri = URI.parse(url)
    load_and_cache_page(uri) { @agent.get(url) }
  end
  
  def click(link)
    uri = to_absolute_uri(link.href, link.page)
    load_and_cache_page(uri) { @agent.click(link) }
  end
  
  def transact
    yield
  end
  
  private
  
  def url_cached?(uri)
    cache_file_exists?(uri, false) || cache_file_exists?(uri, true)
  end
  
  def cache_file_exists?(uri, compressed)
    File.exists?(url_to_filename(uri, compressed))
  end
  
  def fileReader(compressed)
    if compressed
      Zlib::GzipReader
    else
      File
    end
  end
  
  def read_cache(uri)
    # Prefer uncompressed cache files over compressed ones if both exist
    compressed = !cache_file_exists?(uri, false)
    data = fileReader(compressed).open(url_to_filename(uri, compressed)) {|file| file.read}
    if uri.to_s[-4..-1] == ".jpg"
      FileProxy.new(data, uri)
    else
      PageProxy.new(Hpricot(data), uri)
    end
  end
  
  # Returns original page
  def write_cache(uri, page)
    if page.respond_to?(:parser)
      # Write compressed cache files (for normal HTML pages)
      compressed = true
      data = page.parser.to_s
    else
      # Don't compress images
      compressed = false
      data = page.body      
    end
    filename = url_to_filename(uri, compressed)
    FileUtils.mkdir_p(File.dirname(filename))
    if compressed
      Zlib::GzipWriter.open(filename) do |file|
        file.write(data)
        file.close
      end
    else
      File.open(filename, 'w') do |file|
        file.write(data)
      end
    end
    page
  end
  
  def load_and_cache_page(uri)
    if url_cached?(uri)
      read_cache(uri)
    else
      result = yield
      if result.respond_to?(:parser)
        page = PageProxy.new(result.parser, uri)
      else
        page = FileProxy.new(result.body, uri)
      end
      write_cache(uri, page)
    end
  end

  def url_to_filename(url, compressed)
    if compressed
      url_to_compressed_filename(url)
    else
      url_to_uncompressed_filename(url)
    end
  end
  
  def url_to_uncompressed_filename(uri)
    if cache_subdirectory
      "#{@conf.html_cache_path}/#{cache_subdirectory}/#{uri.to_s.tr('/', '_')}"
    else
      "#{@conf.html_cache_path}/#{uri.to_s.tr('/', '_')}"
    end
  end
  
  def url_to_compressed_filename(uri)
    url_to_uncompressed_filename(uri) + ".gz"
  end
  
  def to_absolute_uri(url, cur_page)
    unless url.is_a? URI
      url = url.to_s.strip.gsub(/[^#{0.chr}-#{125.chr}]/) { |match|
        sprintf('%%%X', match.unpack($KCODE == 'UTF8' ? 'U' : 'c')[0])
      }

      url = URI.parse(
              Util.html_unescape(
                url.split(/%[0-9A-Fa-f]{2}|#/).zip(
                  url.scan(/%[0-9A-Fa-f]{2}|#/)
                ).map { |x,y|
                  "#{URI.escape(x)}#{y}"
                }.join('')
              )
            )
    end

    url.path = '/' if url.path.length == 0

    # construct an absolute uri
    if url.relative?
      raise 'no history. please specify an absolute URL' unless cur_page.uri
      base = cur_page.respond_to?(:bases) ? cur_page.bases.last : nil
      url = ((base && base.uri && base.uri.absolute?) ?
              base.uri :
              cur_page.uri) + url
      url = cur_page.uri + url
      # Strip initial "/.." bits from the path
      url.path.sub!(/^(\/\.\.)+(?=\/)/, '')
    end

    return url
  end
  
  class Util
    def self.html_unescape(s)
      return s unless s
      s.gsub(/&(\w+|#[0-9]+);/) { |match|
        number = case match
        when /&(\w+);/
          Hpricot::NamedCharacters[$1]
        when /&#([0-9]+);/
          $1.to_i
        end

        number ? ([number].pack('U') rescue match) : match
      }
    end
  end
  
end

class FileProxy
  def initialize(doc, uri)
    @doc = doc
    @uri = uri
  end
  
  def body
    @doc
  end
end

class PageProxy
  attr_reader :uri
  
  def initialize(doc, uri)
    @doc = doc
    @uri = uri
  end
  
  def parser
    @doc
  end
  
  def links
    WWW::Mechanize::List.new(@doc.search('a').map{|e| LinkProxy.new(e, self)})
  end
  
  def search(text)
    @doc.search(text)
  end
  
  def title
    @doc.search('title').inner_text
  end
end

class LinkProxy
  attr_reader :attributes, :page
  
  def initialize(attributes, page)
    @attributes = attributes
    @page = page
  end
  
  def text
    @attributes.inner_text
  end
  
  alias :to_s :text

  def href
    @attributes['href']
  end
  
  def uri
    URI.parse(href)
  end  
end

