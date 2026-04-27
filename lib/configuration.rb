# frozen_string_literal: true

require "yaml"

class Configuration
  # TODO: Could have conflicts between these and names in the configuration file
  attr_reader :database_host, :database_user, :database_password, :database_name, :file_image_path, :members_xml_path, :xml_path,
              :regmem_pdf_path, :base_dir, :website, :web_path, :app_env

  def load_mysociety_config
    # Load the information from the mysociety configuration
    require "#{web_root}/rblib/config"
    MySociety::Config.set_file("#{web_root}/twfy/conf/general")
    @database_host = @conf["database_host"] || MySociety::Config.get("DB_HOST")
    @database_user = @conf["database_user"] || MySociety::Config.get("DB_USER")
    @database_password = @conf["database_password"] || MySociety::Config.get("DB_PASSWORD")
    @database_name = @conf["database_name"] || MySociety::Config.get("DB_NAME")
    @file_image_path = @conf["file_image_path"] || MySociety::Config.get("FILEIMAGEPATH")
    @members_xml_path = @conf["members_xml_path"] || MySociety::Config.get("PWMEMBERS")
    @xml_path = @conf["xml_path"] || MySociety::Config.get("RAWDATA")
    @website = @conf["website"] || MySociety::Config.get("DOMAIN")
    @web_path = @conf["web_path"] || MySociety::Config.get("WEBPATH")
    @regmem_pdf_path = @conf["regmem_pdf_path"] || MySociety::Config.get("REGMEMPDFPATH")
    @base_dir = @conf["base_dir"] || MySociety::Config.get("BASEDIR")
  end

  def test?
    @app_env == "test"
  end

  def production?
    @app_env == "production"
  end

  def staging?
    @app_env == "staging"
  end

  def development?
    @app_env == "development"
  end

  def initialize(app_env: nil)
    @app_env = app_env || ENV["APP_ENV"]
    @app_env ||= "production" if Dir.pwd.to_s.include?("/production/")
    @app_env ||= "staging" if Dir.pwd.to_s.include?("/staging/")
    @app_env ||= "development"
    puts "Loading config from: #{File.dirname(__FILE__)}/../configuration.yml for #{@app_env}"
    # Load the configuration from the config file
    @conf = YAML.safe_load(File.open("#{File.dirname(__FILE__)}/../configuration.yml"))
    @conf ||= {}
    @conf = @conf.merge(@conf[@app_env]) if @app_env && @conf[@app_env]
    load_mysociety_config
  end

  # Ruby magic
  def method_missing(method_id)
    name = method_id.id2name
    if @conf.key?(name)
      @conf[name]
    else
      super
    end
  end
end
