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
    allow(rig).to receive(:session) { Hash.new }
    rig
  }
  before do
    Ability.instance_variable_set :@role_proxy_config, Hash.new
    rig.instance_variable_set :@current_ability, nil
  end
  after do
    Ability.instance_variable_set :@role_proxy_config, nil
  end

  it do
    is_expected.to be_a Module
  end
  context "is included" do
    subject { request }
    it do
      is_expected.to receive(:remote_ip)
      rig.current_ability
    end
  end
end
