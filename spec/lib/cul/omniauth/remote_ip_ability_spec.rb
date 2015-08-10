require 'spec_helper'

describe Cul::Omniauth::RemoteIpAbility do
  let(:request) {
    DummyRequest.new
  }
  let(:role_config) {
    Hash.new
  }
  let(:rig_class) {
    c = Class.new
    c.include(Cul::Omniauth::RemoteIpAbility)
    c
  }
  let(:current_user) { User.new }
  let(:rig) {
    rig = rig_class.new
    allow(rig).to receive(:request) { request }
    allow(rig).to receive(:current_user) { current_user }
    rig
  }

  it do
    is_expected.to be_a Module
  end
  it do
    expect(request).to receive(:remote_ip)
    rig.current_ability
  end
end
