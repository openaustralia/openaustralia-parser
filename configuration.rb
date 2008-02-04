class Configuration
  
  @@conf = nil
  
  def initialize
    if @@conf.nil?
      # Load the configuration
      @@conf = YAML::load( File.open( 'config.yml' ) )
      @@conf = {} if !@@conf
    end
  end
  
  def proxy_host
    @@conf["proxy"]["host"]
  end
  
  def proxy_port
    @@conf["proxy"]["port"]
  end
  
  def using_proxy?
    @@conf.has_key?("proxy")
  end
end
