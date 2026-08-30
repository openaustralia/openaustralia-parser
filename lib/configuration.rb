# frozen_string_literal: true

require "yaml"
require "sentry-ruby"

class Configuration
  # TODO: Could have conflicts between these and names in the configuration file
  attr_reader :database_host, :database_user, :database_password, :database_name, :file_image_path, :members_xml_path, :xml_path,
              :regmem_pdf_path, :base_dir, :website, :web_path, :app_env, :sentry_dsn

  # Sibling rblib checkout, fixed by this repo's own layout - not the same
  # thing as configuration.yml's web_root, which is legitimately overridable
  # per-environment (and deliberately /dev/null in test) but has nothing to
  # do with where rblib physically lives relative to this file.
  RBLIB_PATH = File.expand_path("../../rblib", __dir__)

  # Loads the MySociety module (idempotent, cheap to call repeatedly), for
  # code that needs it directly - eg lib/sitemap_generator/news.rb's
  # MySociety::Config.fork_php - independent of whether Configuration itself
  # went on to load DB config from it (see load_mysociety_config below,
  # which skips that part whenever configuration.yml already has it).
  def self.require_mysociety_config
    require "#{RBLIB_PATH}/config"
  end

  def load_configuration_file_values
    @database_host = @conf["database_host"]
    @database_user = @conf["database_user"]
    @database_password = @conf["database_password"]
    @database_name = @conf["database_name"]
    @file_image_path = @conf["file_image_path"]
    @members_xml_path = @conf["members_xml_path"]
    @xml_path = @conf["xml_path"]
    @website = @conf["website"]
    @web_path = @conf["web_path"]
    @regmem_pdf_path = @conf["regmem_pdf_path"]
    @base_dir = @conf["base_dir"]
    @sentry_dsn = @conf["sentry_dsn"]
  end

  def load_mysociety_config
    load_configuration_file_values

    # Skip loading external mysociety config if we already have all required fields (e.g., in test environment)
    required_fields = %w[database_host database_user database_password database_name]
    return if required_fields.all? { |field| @conf[field] }

    # Load the information from the mysociety configuration
    self.class.require_mysociety_config
    MySociety::Config.set_file("#{web_root}/twfy/conf/general")
    @database_host ||= MySociety::Config.get("DB_HOST")
    @database_user ||= MySociety::Config.get("DB_USER")
    @database_password ||= MySociety::Config.get("DB_PASSWORD")
    @database_name ||= MySociety::Config.get("DB_NAME")
    @file_image_path ||= MySociety::Config.get("FILEIMAGEPATH")
    @members_xml_path ||= MySociety::Config.get("PWMEMBERS")
    @xml_path ||= MySociety::Config.get("RAWDATA")
    @website ||= MySociety::Config.get("DOMAIN")
    @web_path ||= MySociety::Config.get("WEBPATH")
    @regmem_pdf_path ||= MySociety::Config.get("REGMEMPDFPATH")
    @base_dir ||= MySociety::Config.get("BASEDIR")
    # Same Sentry project as twfy (conf/general's SENTRY_DSN), so the web app
    # and the parser report to the same place. sentry_dsn in configuration.yml
    # overrides it for standalone development (see configuration.yml.example).
    # rblib's MySociety::Config.get treats an explicit nil default the same as
    # no default (raises either way, see its `elsif !default.nil?`), so this
    # must be a real string, not nil, to actually avoid raising.
    @sentry_dsn ||= MySociety::Config.get("SENTRY_DSN", "")
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
