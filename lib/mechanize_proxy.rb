# Very stripped down proxy for WWW::Mechanize
#
# Stores cached html files in directory "html_cache_path" in configuration.yml

class MechanizeProxy
  # By setting cache_subdirectory can put cached files under a subdirectory in the html_cache_path
  attr_accessor :cache_subdirectory
  
  def initialize
    @agent = WWW::Mechanize.new
    @conf = Configuration.new
    
    @agent.set_proxy(@conf.proxy_host, @conf.proxy_port)    
  end
  
  def get(url)
    uri = URI.parse(url)
    load_and_cache_page(uri) { @agent.get(url) }
  end
  
  def click(link)
    uri = to_absolute_uri(link.href, link.page)
    load_and_cache_page(uri) { @agent.click(link) }
  end
  
  def load_and_cache_page(uri)
    filename = url_to_filename(uri.to_s)
    if File.exists?(filename)
      document = Hpricot(File.open(filename) {|file| file.read})
    else
      document = yield.parser
      FileUtils.mkdir_p(File.dirname(filename))
      File.open(filename, 'w') {|file| file.puts(document.to_s) }      
    end
    PageProxy.new(document, uri)    
  end

  private
  
  def url_to_filename(url)
    if cache_subdirectory
      "#{@conf.html_cache_path}/#{cache_subdirectory}/#{url.tr('/', '_')}"
    else
      "#{@conf.html_cache_path}/#{url.tr('/', '_')}"
    end
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

class PageProxy
  attr_reader :uri
  
  def initialize(doc, uri)
    @doc = doc
    @uri = uri
  end
  
  def links
    WWW::Mechanize::List.new(@doc.search('a').map{|e| LinkProxy.new(e, self)})
  end
  
  def search(text)
    @doc.search(text)
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

