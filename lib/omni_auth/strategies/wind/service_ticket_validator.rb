# This is a clone of the OmniAuth CAS ServiceTicketValidator for WIND
# Copyright (c) 2011 Derek Lindahl and CustomInk, LLC
# distributed under the MIT license
# https://github.com/dlindahl/omniauth-cas
module OmniAuth
  module Strategies
    class WIND
      class ServiceTicketValidator < OmniAuth::Strategies::CAS::ServiceTicketValidator
        NS = {wind: 'http://www.columbia.edu/acis/rad/authmethods/wind'}
        def parse_user_info(node)
          return nil if node.nil?
          
          {}.tap do |hash|
            node.children.each do |e|
              node_name = e.name.sub(/^wind:/, '')
              unless e.kind_of?(Nokogiri::XML::Text) || node_name == 'proxies'
                # There are no child elements
                if e.element_children.count == 0
                  hash[node_name] = e.content
                elsif e.element_children.count
                  # WIND style affiliations
                  if node_name == 'affiliations'
                    hash.merge!(affiliations: e.xpath('wind:affil',NS).collect {|x| x.text})
                  else
                    hash[node_name] = [] if hash[node_name].nil?
                    hash[node_name].push(parse_user_info(e))
                  end
                end
              end
            end
          end
        end
        def find_authentication_success(body)
          return nil if body.nil? || body == ''
          begin
            doc = Nokogiri::XML(body)
            begin
              doc.xpath('/wind:serviceResponse/wind:authenticationSuccess', NS)
            rescue Nokogiri::XML::XPath::SyntaxError
              doc.xpath('/serviceResponse/authenticationSuccess')
            end
          rescue Nokogiri::XML::XPath::SyntaxError
            nil
          end
        end
      end
    end
  end
end