# frozen_string_literal: true

require "yaml"
require "sentry-ruby"

class Configuration
  # TODO: Could have conflicts between these and names in the configuration file
  attr_reader :database_host, :database_user, :database_password, :database_name, :file_image_path, :members_xml_path, :xml_path,
              :regmem_pdf_path, :base_dir, :website, :web_path, :app_env, :sentry_dsn

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
    # Same Sentry project as twfy (conf/general's SENTRY_DSN), so the web app
    # and the parser report to the same place. sentry_dsn in configuration.yml
    # overrides it for standalone development (see configuration.yml.example).
    @sentry_dsn = @conf["sentry_dsn"] || MySociety::Config.get("SENTRY_DSN")
  end

  # Reports uncaught exceptions to Sentry, if configured. Safe to call even
  # when sentry_dsn is blank - the SDK just stays disabled and Sentry.* calls
  # become no-ops. Called once, from initialize.
  def init_sentry
    Sentry.init do |config|
      config.dsn = sentry_dsn
      config.environment = app_env
    end
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

  # Runs the given block, reporting any uncaught exception to Sentry before
  # re-raising, so exit codes and existing behaviour don't change. Wrap each
  # top-level entry script's final "SomeClass.new(...).run" call in this.
  # Sentry must already be initialized (ie a Configuration instantiated)
  # before the block runs, or reporting is a no-op.
  def self.report_errors
    yield
  rescue StandardError => e
    Sentry.capture_exception(e)
    raise
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
    init_sentry
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
