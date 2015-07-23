require 'omniauth-cas'
module Cul
  module Omniauth
    autoload :FailureApp, 'cul/omniauth/failure_app'
    autoload :FileConfigurable, 'cul/omniauth/file_configurable'
    autoload :AbilityProxy, 'cul/omniauth/ability_proxy'
    require "cul/omniauth/engine"
  end
end
module OmniAuth
  module Strategies
    require 'omni_auth/strategies/saml'
    require 'omni_auth/strategies/wind'
  end
end
OmniAuth::Strategies::CAS::ServiceTicketValidator.class
class OmniAuth::Strategies::CAS::ServiceTicketValidator
  alias defunct_parse parse_user_info
  alias defunct_success find_authentication_success
  # turns an `<cas:authenticationSuccess>` node into a Hash;
  # returns nil if given nil
  def parse_user_info(node)
    return nil if node.nil?
    {}.tap do |hash|
      node.children.each do |e|
        node_name = e.name.sub(/^cas:/, '')
        unless e.kind_of?(Nokogiri::XML::Text) || node_name == 'proxies'
          # There are no child elements
          if e.element_children.count == 0
            hash[node_name] = e.content
          elsif e.element_children.count
            # JASIG style extra attributes
            if node_name == 'attributes'
              hash.merge!(parse_user_info(e))
            elsif node_name == 'affiliations'
              hash.merge!(affiliations: e.xpath('cas:affil',NS).collect {|x| x.text})
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
        doc.xpath('/cas:serviceResponse/cas:authenticationSuccess')
      rescue Nokogiri::XML::XPath::SyntaxError
        doc.xpath('/serviceResponse/authenticationSuccess')
      end
    rescue Nokogiri::XML::XPath::SyntaxError
      nil
    end
  end
end