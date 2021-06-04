require 'grape'
require 'nokogiri'

require 'paynearme/callbacks/helpers'
require 'paynearme/callbacks/version'
require 'paynearme/callbacks/logger'

module Paynearme
  module Callbacks
    class API < Grape::API
      format :xml
      helpers Helpers

      logger Paynearme::Callbacks::Logger.new(name: self.name)

      def initialize
        super
        API.logger.info "Paynearme::Callbacks::API version #{Paynearme::Callbacks::VERSION}"
      end

      before do
        @start_time = Time.now
      end

      after do
        exec_time = (Time.now - @start_time)*1000.0
        logger.info "Request handled in #{exec_time}ms"
        logger.warn "Request took longer than 6 seconds!" if exec_time >= 6000
      end

      desc 'authorize callback'
      params do
        use :callback_params

        optional :site_order_annotation, type: String
        optional :status, type: String
      end
      get :authorize do
        logger.warn 'This /authorize request is a test! Do not handle tests as real financial events!' if test?

        site_order_identifier = params[:site_order_identifier]

        # This is where you verify the information sent with the
        # request, validate it within your system, and then return a
        # response. Here we just accept payments with order identifiers
        # starting with "TEST"
        accept = valid_signature? && site_order_identifier =~ /^TEST/

        logger.info "Order: #{site_order_identifier} will be #{accept ? 'accepted' : 'declined'}"

        special = handle_special_condition! # if special is non-nil, we want to return our special response.

        if !special
          Nokogiri::XML::Builder.new do |xml|
            t = xml[:t] # get our t: namespace prefix
            t.payment_authorization_response(xml_headers) do
              t.authorization do
                t.pnm_order_identifier params[:pnm_order_identifier]
                t.accept_payment accept ? 'yes' : 'no'

                #You can set custom receipt text here (if you want) - if you
                # don't want custom text, you can omit this
                t.receipt accept ? 'Thank you for your order' : 'Order declined'
                t.memo accept ? Time.now.to_s : "Invalid Payment: #{site_order_identifier}"

              end
            end
          end
        else
          special
        end
      end

      desc 'confirmation callback'
      params do
        use :callback_params

        optional :site_order_annotation, type: String
        optional :status, type: String
      end
      get :confirm do
        logger.warn 'This /confirm request is a test! Do not handle tests as real financial events!' if test?

        if params[:status] and params[:status].downcase == 'decline'
          logger.warn "Transaction #{params[:site_order_identifier]} was declined - do not post, still respond to callback."
        end
        
        # You must lookup the pnm_payment_identifier in your business system and prevent double posting.
        # In the event of a duplicate callback from PayNearMe ( this can sometimes happen in a race or
        # retry condition) you must respond to all duplicates, but do not post the payment.
        # No stub code is provided for this check, and is left to the responsibility of the implementor.
        # Now that you have responded to a /confirm, you need to keep a record of this pnm_payment_identifier.

        pnm_order_identifier = params[:pnm_order_identifier]

        special = handle_special_condition! # if special is non-nil, we want to return our special response.

        if !special
          Nokogiri::XML::Builder.new do |xml|
            t = xml[:t] # get our t: namespace prefix
            t.payment_confirmation_response(xml_headers) do
              t.confirmation do
                t.pnm_order_identifier pnm_order_identifier
              end
            end
          end if valid_signature?
        else
          special
        end

        # Now that you have responded to a /confirm, you need to keep a record
        # of this pnm_order_identifier and DO NOT respond to any other
        # /confirm requests for that pnm_order_identifier.
      end

      # helper to build our logger
      def self.get_logger
        if defined? Rails
          #Logger.new File.open(File.join(Rails.root, 'log', "#{Rails.env}.log"))
          Rails.logger
        else
          Logger.new STDOUT
        end
      end
    end
  end
end
