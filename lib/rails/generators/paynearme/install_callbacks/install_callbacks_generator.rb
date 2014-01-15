# Install PayNearMe::Callbacks::API to a rails application

require 'rails/generators'

module Paynearme
  module Generators

    class InstallCallbacksGenerator < Rails::Generators::Base
      source_root File.join(File.dirname(__FILE__), '..', '..', '..', '..')

      def create_grape_initializer
        create_file "config/initializers/paynearme_api.rb", <<-FILE
# Grape API
Rails.application.config.paths.add "app/api", glob: "**/*.rb"
Rails.application.config.autoload_paths += Dir["\#{Rails.root}/app/api/*"]

# Configure your API settings here
Rails.application.config.paynearme_secret = "d33af5664496dc4d"
Rails.application.config.paynearme_site_identifier = "CALLBACK_RUBY"
        FILE
      end

      def create_pnm_callbacks
        copy_file "paynearme/callbacks/api.rb", "app/api/paynearme.rb"
      end

      def create_routes
        route "mount Paynearme::Callbacks::API => '/callbacks'"
      end
    end
  end
end