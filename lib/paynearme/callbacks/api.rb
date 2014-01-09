require 'grape'
require 'nokogiri'

module Paynearme
  module Callbacks
    SITE_SECRET_KEY ='d33af5664496dc4d'

    class API < Grape::API
      format :xml
      # version '2.0', using: :param, parameter: 'version'

      helpers do
        def logger
          API.logger
        end

        def signature (secret, params)
          sig = params.keys.sort.select { |p|
            p =~ /^pnm_.+|^site_.+|^due_to_site_.+|^(?:net_)?payment_.+|^version$|^timestamp$|^test$/ and !params[p].nil? and params[p] != ''
          }.inject('') { |memo, cur| memo += "#{cur}#{params[cur]}" }
          Digest::MD5.hexdigest(sig + secret)
        end

        def valid_signature? (params)
          sig = signature SITE_SECRET_KEY, params
          provided = params[:signature]
          logger.debug "Signature - provided: #{provided}, expected: #{sig}"

          sig == provided
        end

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
        requires :pnm_order_identifier, type: String
        requires :signature, type: String
        requires :version, type: String
        requires :timestamp, type: Integer

        optional :site_order_identifier, type: String
        optional :test, type: Boolean
      end
      get :authorize do
        site_order_identifier = params[:site_order_identifier]

        accept = false
        if valid_signature?(params) and site_order_identifier =~ /^TEST/
          accept = true
        end
        logger.info "Order: #{site_order_identifier} will be #{accept ? 'accepted' : 'declined'}"

        Nokogiri::XML::Builder.new { |xml|
          t = xml[:t]
          schema = "pnm_xmlschema_v#{params[:version].gsub('.', '_')}"
          t.payment_authorization_response('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                                           'xsi:schemaLocation' => "http://www.paynearme.com/api/#{schema} #{schema}.xsd",
                                           'xmlns:t' => "http://www.paynearme.com/api/#{schema}") {
            t.authorization {
              t.pnm_order_identifier params[:pnm_order_identifier]
              t.accept_payment accept ? 'yes' : 'no'
            }
          }
        }
      end

      ##########
      # /confirm callback
      #########################################################################
      params do
        requires :pnm_order_identifier, type: String
      end
      get :confirm do

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
        } if valid_signature? params
      end
    end
  end
end



