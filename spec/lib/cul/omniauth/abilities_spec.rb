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
    c.class_eval do
      include Cul::Omniauth::RemoteIpAbility
    end
    c
  }
  let(:current_user) { User.new }
  let(:proxy) { Cul::Omniauth::AbilityProxy.new }
  let(:rig) {
    rig = rig_class.new
    allow(rig).to receive(:request) { request }
    allow(rig).to receive(:current_user) { current_user }
    allow(rig).to receive(:session) { Hash.new }
    rig
  }

  subject do
    rig.current_ability
  end

  context "when no valid session, role or id" do
    before do
      Ability.instance_variable_set :@role_proxy_config, symbolize_hash_keys(rules)
      rig.instance_variable_set :@current_ability, nil
    end
    after do
      Ability.instance_variable_set :@role_proxy_config, nil
    end
    let(:rules) do
      YAML.load(fixture('test/role_config/and.yml').read)['_all_environments']
    end
    it do
      expect(subject.can?  :download, proxy).not_to be
    end
  end

  context "when user has a valid role" do
    before do
      Ability.instance_variable_set :@role_proxy_config, symbolize_hash_keys(rules)
      rig.instance_variable_set :@current_ability, nil
    end
    after do
      Ability.instance_variable_set :@role_proxy_config, nil
    end
    let(:rules) do
      YAML.load(fixture('test/role_config/and.yml').read)['_all_environments']
    end
    context "in a session" do
      before do
        allow(rig).to receive(:session) { {'devise.roles' => [:'downloaders']} }
      end
      it do
        expect(subject.can? :download, proxy).to be
      end
    end
    context "in a user" do
      it do
        #allow(current_user).to receive(:role?).and_return(false)
        allow(current_user).to receive(:role?).with(:*).and_return(true)
        allow(current_user).to receive(:role?).with(:downloaders).and_return(true)
        expect(subject.can? :download, proxy).to be
      end
    end
  end

  context "when combining with and" do
    let(:rules) do
      YAML.load(fixture('test/role_config/and.yml').read)['_all_environments']
    end
    before do
      Ability.instance_variable_set :@role_proxy_config, symbolize_hash_keys(rules)
      rig.instance_variable_set :@current_ability, nil
    end
    after do
      Ability.instance_variable_set :@role_proxy_config, nil
    end
    context "when the IP is on the approved list and login is right" do
      before do
        allow(current_user).to receive(:uid).and_return('test_user')
        request.remote_ip = '255.255.255.255'
      end
      it do
        expect(subject.can?  :download, proxy).to be
      end
    end
    context "when the IP is not on the approved list" do
      before do
        allow(current_user).to receive(:uid).and_return('test_user')
        request.remote_ip = '255.255.255.1'
      end
      it do
        expect(subject.can?  :download, proxy).not_to be
      end
    end
    context "when login is wrong" do
      before do
        allow(current_user).to receive(:uid).and_return('wrong_user')
        request.remote_ip = '255.255.255.255'
      end
      it do
        expect(subject.can?  :download, proxy).not_to be
      end
    end
  end
  context "when combining with or" do
    let(:rules) do
      YAML.load(fixture('test/role_config/or.yml').read)['_all_environments']
    end
    before do
      Ability.instance_variable_set :@role_proxy_config, symbolize_hash_keys(rules)
      rig.instance_variable_set :@current_ability, nil
    end
    after do
      Ability.instance_variable_set :@role_proxy_config, nil
    end
    subject do
      rig.current_ability
    end
    context "when the IP is on the approved list and login is right" do
      before do
        allow(current_user).to receive(:uid).and_return('test_user')
        request.remote_ip = '255.255.255.255'
      end
      it do
        expect(subject.can?  :download, proxy).to be
      end
    end
    context "when neither IP or login is approved" do
      before do
        allow(current_user).to receive(:uid).and_return('wrong_user')
        request.remote_ip = '255.255.255.1'
      end
      it do
        expect(subject.can?  :download, proxy).not_to be
      end
    end
    context "when the IP is not on the approved list" do
      before do
        allow(current_user).to receive(:uid).and_return('test_user')
        request.remote_ip = '255.255.255.1'
      end
      it do
        expect(subject.can?  :download, proxy).to be
      end
    end
    context "when login is wrong" do
      before do
        allow(current_user).to receive(:uid).and_return('wrong_user')
        request.remote_ip = '255.255.255.255'
      end
      it do
        expect(subject.can?  :download, proxy).to be
      end
    end
  end
end
