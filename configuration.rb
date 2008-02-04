class Configuration
  
  @@conf = nil
  
  def initialize
    if @@conf.nil?
      # Load the configuration
      @@conf = YAML::load( File.open( 'configuration.yml' ) )
      @@conf = {} if !@@conf
    end
  end
  
  def proxy_host    
    @@conf["proxy"]["host"] if @@conf.has_key?("proxy")
  end
  
  def proxy_port
    @@conf["proxy"]["port"] if @@conf.has_key?("proxy")
  end
  
  def web_root
    @@conf["web_root"]
  end
end
