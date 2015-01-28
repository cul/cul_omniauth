require 'spec_helper'

describe OmniAuth::Strategies::WIND::ServiceTicketValidator do
  it "should be a module" do
    expect(OmniAuth::Strategies::WIND::ServiceTicketValidator).to be_a Class
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
      mock = double('ticket')
      mock
    end
    subject do
      OmniAuth::Strategies::WIND::ServiceTicketValidator.new(strategy, options, return_to_url, ticket)
    end
    it do
      allow(subject).to receive(:get_service_response_body) {
        fixture('test/wind/success_affils.xml') {|io| io.read }
      }
      user_info = subject.call.user_info
      puts user_info.inspect
      expect(user_info[:affiliations].size).to eql(2)
    end
  end
end
