# This is a clone of the OmniAuth CAS ServiceTicketValidator for WIND
# Copyright (c) 2011 Derek Lindahl and CustomInk, LLC
# distributed under the MIT license
# https://github.com/dlindahl/omniauth-cas
module OmniAuth
  module Strategies
    class SAML
      class ServiceTicketValidator < OmniAuth::Strategies::CAS::ServiceTicketValidator
       ART_TEMPLATE = "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\">" +
                     "<SOAP-ENV:Header/><SOAP-ENV:Body>" +
                     "<samlp:Request IssueInstant=\"%s\" RequestID=\"%s\" MajorVersion=\"1\" MinorVersion=\"1\" xmlns:samlp=\"urn:oasis:names:tc:SAML:1.0:protocol\">" +
                     "<samlp:AssertionArtifact>%s</samlp:AssertionArtifact>" +
                     "</samlp:Request>" +
                     "</SOAP-ENV:Body>" +
                     "</SOAP-ENV:Envelope>"
        NAME_ID_XPATH = './samla:Assertion/samla:AuthenticationStatement/samla:Subject/samla:NameIdentifier'
        AFFIL_VALUE_XPATH = './samla:Assertion/samla:AttributeStatement/samla:Attribute[@AttributeName=\'affiliation\']/samla:AttributeValue'
        def initialize(strategy, options, return_to_url, ticket)
          super
          @ticket = ticket
          @ticket_host = URI(return_to_url).host
        end
        def parse_user_info(node)
          return nil if node.nil?
          {}.tap do |hash|
            node.xpath(NAME_ID_XPATH, SAML_NS).each {|n| hash['user'] = n.text }
            hash['affiliations'] = node.xpath(AFFIL_VALUE_XPATH, SAML_NS).inject([]) {|m,v| m << v.text; m}
          end
        end
        def find_authentication_success(body)
          return nil if body.nil? || body == ''
          begin
            doc = Nokogiri::XML(body)
            begin
              prefix = nil
              doc.xpath('//sprot:Response',SAML_NS).each do |n|
                n.namespace_definitions.each do |ns|
                  if ns.href == 'urn:oasis:names:tc:SAML:1.0:protocol'
                    prefix = ns.prefix
                  end
                  prefix ||= n.namespace.prefix
                end
              end
              prefix = prefix + ':' if prefix
              xpath = '//sprot:Response/sprot:Status/sprot:StatusCode[@Value=\'' + prefix + 'Success\']/../..'
              doc.xpath(xpath, SAML_NS)
            rescue Nokogiri::XML::XPath::SyntaxError
              doc.xpath('//Response/Status/StatusCode[@Value=\'Success\']/../..')
            end
          rescue Nokogiri::XML::XPath::SyntaxError
            nil
          end
        end
        def get_service_request_body
          ART_TEMPLATE % [Time.now.utc.iso8601(3), SecureRandom.hex(16), @ticket]
        end
        # retrieves the `<sprot:Response>` XML from the CAS server
        def get_service_response_body
          result = ''
          http = Net::HTTP.new(@uri.host, @uri.port)
          http.use_ssl = @uri.port == 443 || @uri.instance_of?(URI::HTTPS)
          if http.use_ssl?
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @options.disable_ssl_verification?
            http.ca_path = @options.ca_path
          end
          http.start do |c|
            body = get_service_request_body
            headers = {
              "Content-Type"=>"text/xml",
              "Content-Length" => body.size.to_s,
              'SOAPAction' => "http://www.oasis-open.org/committees/security"
            }
            response = c.post "#{@uri.path}?#{@uri.query}", body, headers
            result = response.body
          end
          result
        end
      end
    end
  end
end