require 'grape'
require 'nokogiri'

require 'paynearme/callbacks/helpers'
require 'paynearme/callbacks/version'

module Paynearme
  module Callbacks
    class API < Grape::API
      format :xml
      helpers Helpers

      def initialize
        super
        API.logger.info "Paynearme::Callbacks::API version #{Paynearme::Callbacks::VERSION}"
      end

      before do
        @start_time = Time.now
      end

      after do
        logger.info "Request handled in #{(Time.now - @start_time)*1000.0}ms"
      end

      ##########
      # /authorize callback
      #########################################################################
      params do
        # Common params (future versions will pull this to a helper - requires grape 0.7 to be released)
        requires :pnm_order_identifier, type: String
        requires :signature, type: String
        requires :version, type: String
        requires :timestamp, type: Integer
        optional :site_order_identifier, type: String
        optional :site_order_annotation, type: String
        optional :test, type: Boolean
        optional :status, type: String
      end
      get :authorize do
        logger.info 'This request is a test! Do not handle tests as real financial events!' if test?

        site_order_identifier = params[:site_order_identifier]

        accept = false
        if valid_signature? and site_order_identifier =~ /^TEST/
          accept = true
        end
        logger.info "Order: #{site_order_identifier} will be #{accept ? 'accepted' : 'declined'}"

        special = handle_special_condition
        if special.nil?
          Nokogiri::XML::Builder.new do |xml|
            t = xml[:t]
            schema = "pnm_xmlschema_v#{params[:version].gsub('.', '_')}"
            t.payment_authorization_response('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                                             'xsi:schemaLocation' => "http://www.paynearme.com/api/#{schema} #{schema}.xsd",
                                             'xmlns:t' => "http://www.paynearme.com/api/#{schema}") do
              t.authorization do
                t.pnm_order_identifier params[:pnm_order_identifier]
                t.accept_payment accept ? 'yes' : 'no'
              end
            end
          end
        else
          special
        end
      end

      ##########
      # /confirm callback
      #########################################################################
      params do
        # Common params (future versions will pull this to a helper - requires grape 0.7 to be released)
        requires :pnm_order_identifier, type: String
        requires :signature, type: String
        requires :version, type: String
        requires :timestamp, type: Integer
        optional :site_order_identifier, type: String
        optional :site_order_annotation, type: String
        optional :test, type: Boolean
        optional :status, type: String
      end
      get :confirm do
        logger.info 'This request is a test! Do not handle tests as real financial events!' if test?

        if params[:status] and params[:status].downcase == 'decline'
          logger.info "Transaction was declined - do not post, still respond to callback."
        end

        Nokogiri::XML::Builder.new { |xml|
          t = xml[:t]
          schema = "pnm_xmlschema_v#{params[:version].gsub('.', '_')}"
          t.payment_confirmation_response('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                                          'xsi:schemaLocation' => "http://www.paynearme.com/api/#{schema} #{schema}.xsd",
                                          'xmlns:t' => "http://www.paynearme.com/api/#{schema}") {
            t.confirmation {
              t.pnm_order_identifier params[:pnm_order_identifier]
            }
          }
        } if valid_signature?
      end
    end
  end
end



