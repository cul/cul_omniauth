require 'spec_helper'

describe Cul::Omniauth::Abilities do
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
    expect(Cul::Omniauth::RemoteIpAbility).to be_a Module
  end
  describe Cul::Omniauth::RemoteIpAbility do
    it do
      expect(request).to receive(:remote_ip)
      rig.current_ability
    end
  end
  describe "configured for a remote ip" do
    before do
      rules = YAML.load(fixture('test/role_config/and.yml').read)['_all_environments']
      Ability.instance_variable_set :@role_proxy_config, symbolize_hash_keys(rules)
      rig.instance_variable_set :@current_ability, nil
    end
    after do
      Ability.instance_variable_set :@role_proxy_config, nil
    end
    describe "should allow when the IP is on the approved list and login is right" do
      it "has remote_ip in proxy" do
        proxy = Cul::Omniauth::AbilityProxy.new(remote_ip: '255.255.255.255', user_id: 'test_user')
        result = rig.current_ability.can? :download, proxy
        expect(result).to be
      end
    end
    context "should deny when the IP is not on the approved list or login is wrong" do
      it "should deny when the IP is not on the approved list" do
        request.remote_ip = nil
        proxy = Cul::Omniauth::AbilityProxy.new(remote_ip: '255.255.255.1', user_id: 'test_user')
        result = rig.current_ability.can? :download, proxy
        expect(result).not_to be
      end
      it "should deny when login is wrong" do
        request.remote_ip = nil
        proxy = Cul::Omniauth::AbilityProxy.new(remote_ip: '255.255.255.255', user_id: 'wrong_user')
        result = rig.current_ability.can? :download, proxy
        expect(result).not_to be
      end
    end
  end
end
