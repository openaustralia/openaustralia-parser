require 'house_period'

class Person
  attr_reader :name, :id
  attr_accessor :image_url
  
  @@id = 10001
  # Sizes of small thumbnail pictures of members
  @@THUMB_WIDTH = 44
  @@THUMB_HEIGHT = 59
  
  def initialize(name)
    @name = name
    @house_periods = []
    @id = @@id
    @@id = @@id + 1
  end
  
  # Adds a single continuous period when this person was in the house of representatives
  # Note that there might be several of these per person
  def add_house_period(params)
    @house_periods << HousePeriod.new(params.merge(:name => @name))
  end
  
  def display
    puts "Member: #{@name.informal_name}"
    @house_periods.each do |p|
      puts "  start: #{p.from_date} #{p.from_why}, end: #{p.to_date} #{p.to_why}"    
    end    
  end

  def output_person(x)
    x.person(:id => "uk.org.publicwhip/person/#{@id}", :latestname => @name.informal_name) do
      @house_periods.each do |p|
        if p.current?
          x.office(:id => "uk.org.publicwhip/member/#{p.id}", :current => "yes")
        else
          x.office(:id => "uk.org.publicwhip/member/#{p.id}")
        end
      end
    end
  end

  def output_house_periods(x)
    @house_periods.each {|p| p.output(x)}
  end 

  def image(width, height)
    if @image_url
      conf = Configuration.new
      res = Net::HTTP::Proxy(conf.proxy_host, conf.proxy_port).get_response(@image_url)
      begin
        image = Magick::Image.from_blob(res.body)[0]
        image.resize_to_fit(width, height)
      rescue
        puts "WARNING: Could not load image #{@image_url}"
      end
    end
  end
  
  def small_image
    image(@@THUMB_WIDTH, @@THUMB_HEIGHT)
  end
  
  def big_image
    image(@@THUMB_WIDTH * 2, @@THUMB_HEIGHT * 2)
  end
end
