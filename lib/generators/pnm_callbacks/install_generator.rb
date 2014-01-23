require 'rails/generators'

module PnmCallbacks
  module Generators

    class InstallGenerator < Rails::Generators::Base
      class_option :routes, type: :boolean, default: true, desc: "Add routes to application"
      class_option :route, type: :string, default: '/callbacks', desc: "Mount point for callbacks api"
      desc "Install the PayNearMe callbacks API into your rails application"
      source_root File.join(File.dirname(__FILE__), '..', '..')

      def create_grape_initializer
        create_file "config/initializers/paynearme_api.rb", <<-FILE
# Grape API
Rails.application.config.paths.add "app/api", glob: "**/*.rb"
Rails.application.config.autoload_paths += Dir["\#{Rails.root}/app/api/*"]

# Configure your API settings here
Rails.application.config.paynearme_secret = "d33af5664496dc4d"
Rails.application.config.paynearme_site_identifier = "CALLBACK_RUBY"
Rails.application.config.paynearme_callback_version = '2.0'
        FILE
      end

      def create_pnm_callbacks
        copy_file "paynearme/callbacks/api.rb", "app/api/paynearme.rb"
      end

      def create_routes
        route "mount Paynearme::Callbacks::API => '#{options.route}'" if options.routes?
      end

    end

  end
end

