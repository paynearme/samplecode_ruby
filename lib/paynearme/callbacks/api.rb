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
        logger.info 'This /authorize request is a test! Do not handle tests as real financial events!' if test?

        site_order_identifier = params[:site_order_identifier]

        # This is where you verify the information sent with the
        # request, validate it within your system, and then return a
        # response. Here we just accept payments with order identifiers
        # starting with "TEST"
        accept = false
        if valid_signature? and site_order_identifier =~ /^TEST/
          accept = true
        end
        logger.info "Order: #{site_order_identifier} will be #{accept ? 'accepted' : 'declined'}"

        special = handle_special_condition!
        if special.nil?
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
        logger.info 'This /confirm request is a test! Do not handle tests as real financial events!' if test?

        if params[:status] and params[:status].downcase == 'decline'
          logger.info "Transaction was declined - do not post, still respond to callback."
        end

        # You must lookup the pnm_order_identifier in your business system and
        # prevent double posting. In the event of a duplicate, ignore the
        # posting (do not reply). No stub code is provided for this check, and
        # is left to the responsibility of the implementor.
        pnm_order_identifier = params[:pnm_order_identifier]


        special = handle_special_condition!
        if special.nil?
          Nokogiri::XML::Builder.new do |xml|
            t = xml[:t] # get our t: namespace prefix
            t.payment_confirmation_response(xml_headers) {
              t.confirmation {
                t.pnm_order_identifier pnm_order_identifier
              }
            }
          end if valid_signature?
        else
          special
        end

        # Now that you have responded to a /confirm, you need to keep a record
        # of this pnm_order_identifier and DO NOT respond to any other
        # /confirm requests for that pnm_order_identifier.

      end
    end
  end
end



