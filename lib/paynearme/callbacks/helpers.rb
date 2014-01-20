# Common helpers for PayNearMe callbacks

require 'grape'

module Paynearme
  module Callbacks
    module Helpers
      #extend Grape::API::Helper

      ## This will work with Grape ~> 0.7.0
      #params :callback_params do
      #  requires :pnm_order_identifier, type: String
      #  requires :signature, type: String
      #  requires :version, type: String
      #  requires :timestamp, type: Integer
      #
      #  optional :site_order_identifier, type: String
      #  optional :test, type: Boolean
      #end

      def logger
        if defined? Rails
          Rails.logger
        else
          API.logger
        end
      end

      def secret_key
        if defined? Rails
          Rails.application.config.paynearme_secret
        else
          'd33af5664496dc4d'
        end
      end

      def site_identifier
        if defined? Rails
          Rails.application.config.paynearme_site_identifier
        else
          'CALLBACKS_RUBY_SITE_ID'
        end
      end

      def signature (secret, params)
        rejections = ['signature', 'route_info'] # part of grape
        keys = params.keys.sort.reject { |key| rejections.include? key }
        sig = keys.inject('') { |memo, cur| "#{memo}#{cur}#{params[cur]}" }
        logger.debug "Signature string: #{sig + secret}"
        Digest::MD5.hexdigest(sig + secret)
      end

      def valid_signature?
        sig = signature secret_key, params
        provided = params[:signature]
        logger.debug "Signature - provided: #{provided}, expected: #{sig}, secret: '#{secret_key}'"
        valid = sig == provided

        logger.info "Signature is #{valid ? 'VALID' : 'INVALID'}"
        valid
      end

      def test?
        !params[:test].nil? and params[:test]
      end

      ## Test hackery - returns a response - if nil, handle normally
      def handle_special_condition!
        arg = params[:site_order_annotation]
        if arg.nil?
          return nil
        elsif arg =~ /^confirm_delay_([0-9]+)/
          logger.info "Delaying response by #{$1} seconds"
          sleep $1
        elsif arg == 'confirm_bad_xml'
          logger.info 'Responding with bad/broken xml'
          return '<result'
        elsif arg == 'confirm_blank'
          logger.info 'Responding with a blank response'
          return ''
        elsif arg == 'confirm_redirect'
          logger.info 'Redirecting to /'
          redirect '/'
        end
        logger.info 'Reached end of #handle_special_condition, returning nil - handle rest of response as usual.'
        nil
      end

      # XML Schema and namespaces
      def xml_headers
        schema = "pnm_xmlschema_v#{params[:version].gsub('.', '_')}"
        {
            'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
            'xsi:schemaLocation' => "http://www.paynearme.com/api/#{schema} #{schema}.xsd",
            'xmlns:t' => "http://www.paynearme.com/api/#{schema}"
        }
      end

    end

  end
end
