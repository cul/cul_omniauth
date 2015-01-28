# This is a clone of the OmniAuth CAS Strategy for WIND
# Copyright (c) 2011 Derek Lindahl and CustomInk, LLC
# distributed under the MIT license
# https://github.com/dlindahl/omniauth-cas
require 'omniauth'
require 'addressable/uri'

module OmniAuth
  module Strategies
    class WIND
      include OmniAuth::Strategy
      # Custom Exceptions
      class MissingWINDTicket < StandardError; end
      class InvalidWINDTicket < StandardError; end
      autoload :ServiceTicketValidator, 'omni_auth/strategies/wind/service_ticket_validator'
      autoload :LogoutRequest, 'omni_auth/strategies/wind/lgout_request'

      attr_accessor :raw_info
      alias_method :user_info, :raw_info

      option :name, :wind # Required property by OmniAuth::Strategy

      option :host, 'wind.columbia.edu'
      option :port, nil
      option :path, nil
      option :ssl,  true
      option :service_validate_url, '/validate'
      option :login_url,            '/login'
      option :service, nil
      option :logout_url,           '/logout'
      option :on_single_sign_out,   Proc.new {}
      # A Proc or lambda that returns a Hash of additional user info to be
      # merged with the info returned by the CAS server.
      #
      # @param [Object] An instance of OmniAuth::Strategies::CAS for the current request
      # @param [String] The user's Service Ticket value
      # @param [Hash] The user info for the Service Ticket returned by the CAS server
      #
      # @return [Hash] Extra user info
      option :fetch_raw_info,       Proc.new { Hash.new }
      # Make all the keys configurable with some defaults set here
      option :uid_field, 'user'
      option :name_key, 'name'
      option :email_key, 'email'
      option :nickname_key, 'user'
      option :first_name_key, 'first_name'
      option :last_name_key, 'last_name'
      option :location_key, 'location'

      # As required by https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
      AuthHashSchemaKeys = %w{name email nickname first_name last_name location}
      info do
        prune!({
          name: raw_info[options[:name_key].to_s],
          email: raw_info[options[:email_key].to_s],
          nickname: raw_info[options[:nickname_key].to_s],
          first_name: raw_info[options[:first_name_key].to_s],
          last_name: raw_info[options[:last_name_key].to_s],
          location: raw_info[options[:location_key].to_s],
        })
      end

      extra do
        prune!(
          raw_info.delete_if{ |k,v| AuthHashSchemaKeys.include?(k) }
        )
      end

      uid do
        raw_info[options[:uid_field].to_s]
      end

      credentials do
        prune!({ ticket: @ticket })
      end

      def login_url(service)
        wind_url + append_params(options.login_url, { destination: service, service: options.service })
      end
      def logout_url(service)
        wind_url + append_params(options.logout_url, { destination: service})
      end
      # Build a WIND host with protocol and port
      #
      #
      def wind_url
        extract_url if options['url']
        validate_wind_setup
        @wind_url ||= begin
          uri = Addressable::URI.new
          uri.host = options.host
          uri.scheme = options.ssl ? 'https' : 'http'
          uri.port = options.port
          uri.path = options.path
          uri.to_s
        end
      end

      def extract_url
        url = Addressable::URI.parse(options.delete('url'))
        options.merge!(
          'host' => url.host,
          'port' => url.port,
          'path' => url.path,
          'ssl' => url.scheme == 'https'
        )
      end

      def validate_wind_setup
        if options.host.nil? || options.login_url.nil?
          raise ArgumentError.new(":host and :login_url MUST be provided")
        end
      end

      def service_validate_url(service_url, ticket)
        service_url = Addressable::URI.parse(service_url)
        service_url.query_values = service_url.query_values.tap { |qs| qs.delete('ticketid') }
        r = wind_url + append_params(options.service_validate_url, {
          ticketid: ticket
        })
        r
      end

      def callback_phase
        if on_sso_path?
          single_sign_out_phase
        else
          @ticket = request.params['ticketid']
          return fail!(:no_ticket, MissingWINDTicket.new('No WIND Ticket')) unless @ticket
          fetch_raw_info(@ticket)
          return fail!(:invalid_ticket, InvalidWINDTicket.new('Invalid WIND Ticket')) if raw_info.empty?
          super
        end
      end
      def request_phase
        service_url = append_params(callback_url, return_url)

        [
          302,
          {
            'Location' => login_url(service_url),
            'Content-Type' => 'text/plain'
          },
          ["You are being redirected to WIND for sign-in."]
        ]
      end

      def on_sso_path?
        request.post? && request.params.has_key?('logoutRequest')
      end

      def single_sign_out_phase
        logout_request_service.new(self, request).call(options)
      end

      def validate_service_ticket(ticket)
        OmniAuth::Strategies::WIND::ServiceTicketValidator.new(self, options, callback_url, ticket).call
      end

      def append_params(base, params)
        params = params.each { |k,v| v = Rack::Utils.escape(v) }
        Addressable::URI.parse(base).tap do |base_uri|
          base_uri.query_values = (base_uri.query_values || {}).merge(params)
        end.to_s
      end

      # Validate the Service Ticket
      # @return [Object] the validated Service Ticket
      def validate_service_ticket(ticket)
        ServiceTicketValidator.new(self, options, callback_url, ticket).call
      end

    private

      def fetch_raw_info(ticket)
        ticket_user_info = validate_service_ticket(ticket).user_info
        custom_user_info = options.fetch_raw_info.call(self, options, ticket, ticket_user_info)
        self.raw_info = ticket_user_info.merge(custom_user_info)
      end

      # Deletes Hash pairs with `nil` values.
      # From https://github.com/mkdynamic/omniauth-facebook/blob/972ed5e3456bcaed7df1f55efd7c05c216c8f48e/lib/omniauth/strategies/facebook.rb#L122-127
      def prune!(hash)
        hash.delete_if do |_, value|
          prune!(value) if value.is_a?(Hash)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end
      end

      def return_url
        # If the request already has a `url` parameter, then it will already be appended to the callback URL.
        if request.params && request.params['url']
          {}
        else
          { url: request.referer }
        end
      end

      def logout_request_service
        LogoutRequest
      end
    end
  end
end
OmniAuth.config.add_camelization 'wind', 'WIND'