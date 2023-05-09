require 'spec_helper'

describe Cul::Omniauth::Users do

  it do
    is_expected.to be_a Module
  end
  context "is included" do
    let(:token){ {'uid'=> uid, 'provider'=> provider} }
    let(:uid) { 'foo' }
    let(:provider) { 'lol' }
    subject { User }
    context "token has no uid" do
      before do
        token['uid'] = nil
      end
      it do
        expect(subject.find_for_provider(token, provider)).not_to be
      end
    end
    context "existing user" do
      let(:users) { [double(User)]}
      it do
        is_expected.to receive(:where).with({ uid: uid, provider: provider }).and_return(users)
        is_expected.not_to receive(:"create!")
        subject.find_for_provider(token, provider)
      end
    end
    context "new user" do
      let(:users) { []}
      it do
        is_expected.to receive(:where).with({ uid: uid, provider: provider }).and_return(users)
        is_expected.to receive(:"create!").with({ uid: uid, provider: provider }).and_return(double(User))
        subject.find_for_provider(token, provider)
      end
    end
    ["cas", "saml", "wind"].each do |method|
      context "find with #{method} provider" do
        it do
          is_expected.to receive(:find_for_provider).with(token,method)
          subject.send :"find_for_#{method}", token
        end
      end
    end
  end
end