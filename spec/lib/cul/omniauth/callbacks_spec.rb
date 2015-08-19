require 'spec_helper'

describe Cul::Omniauth::Callbacks do
  let(:oa_response) do
    double('OmniauthResponse')
  end
  let(:request) {
    DummyRequest.new
  }
  let(:role_config) {
    Hash.new
  }
  let(:rig_class) {
    c = Class.new
    c.class_eval do
      attr_accessor :current_user, :request, :flash, :session
      include Cul::Omniauth::Callbacks
    end
    c
  }
  let(:current_user) { User.new }
  let(:rig) {
    rig = rig_class.new
    rig
  }

  it do
    is_expected.to be_a Module
  end
  context "is included" do
    subject { rig }
    before do
      rig.current_user = current_user
      rig.request = request
      rig.session = {}
      allow(oa_response).to receive(:uid).and_return('foo')
      allow(oa_response).to receive(:extra).and_return(OpenStruct.new)
      request.env = {'omniauth.auth' => oa_response}
      rig.flash = {}
    end
    ['SAML', 'CAS', 'WIND'].each do |method|
      context "logging in with #{method}" do
        before do
          allow(oa_response).to receive(:provider).and_return(method)
        end
        it do
          is_expected.to receive(:redirect_to)
          is_expected.to receive(:root_url)
          expect(User).not_to receive("find_for_#{method.downcase}".to_sym)
          subject.send method.downcase.to_sym
          expect(rig.flash[:notice]).to be
        end
        context "user is persisted" do
          before do
            current_user.persisted = true
          end
          it do
            is_expected.to receive(:sign_in_and_redirect)
            subject.send method.downcase.to_sym
            expect(rig.flash[:notice]).to be
          end
          context "no current_user" do
            before do
              rig.current_user = nil
            end
            it do
              is_expected.to receive(:sign_in_and_redirect)
              expect(User).to receive("find_for_#{method.downcase}".to_sym).and_return(current_user)
              subject.send method.downcase.to_sym
              expect(rig.flash[:notice]).to be
            end
          end
        end
      end
    end
  end
end