require 'spec_helper'

describe OmniAuth::Strategies::SAML::ServiceTicketValidator do
  it "should be a class" do
    expect(OmniAuth::Strategies::SAML::ServiceTicketValidator).to be_a Class
  end
  describe "success parsing" do
    let(:strategy) do
      mock = double('strategy')
      allow(mock).to receive(:service_validate_url) {'/validate'}

      mock
    end
    let(:options) do
      {}
    end
    let(:return_to_url) do
      'http://test.server/test'
    end
    let(:ticket) do
      SecureRandom.hex(16)
    end
    subject do
      OmniAuth::Strategies::SAML::ServiceTicketValidator.new(strategy, options, return_to_url, ticket)
    end
    it "should generate the ticket envelope" do
      pattern = "<samlp:AssertionArtifact>#{ticket}</samlp:AssertionArtifact>"
      SAML_NS = {
        samla: "urn:oasis:names:tc:SAML:1.0:assertion",
        samlp: "urn:oasis:names:tc:SAML:1.0:protocol",
      }
      actual = Nokogiri::XML(subject.get_service_request_body).xpath('//samlp:AssertionArtifact', SAML_NS).text
      expect(actual).to eql(ticket)
    end
    context "on a successful authentication" do
      before do
        allow(subject).to receive(:get_service_response_body) {
          fixture('test/saml/success_affils.xml') {|io| io.read }
        }
      end
      it "should find the user id" do
        user_info = subject.call.user_info
        puts user_info.inspect
        expect(user_info['user']).to eql('de3')
      end
      it "should find the affils" do
        user_info = subject.call.user_info
        puts user_info.inspect
        expect(user_info['affiliations'].size).to eql(6)
      end
    end
  end
end
