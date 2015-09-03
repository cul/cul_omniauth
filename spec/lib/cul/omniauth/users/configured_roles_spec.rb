require 'spec_helper'

describe Cul::Omniauth::Users::ConfiguredRoles do

  it do
    is_expected.to be_a Module
  end
  context "is included" do
    let(:uid) { 'foo' }
    let(:rules) do
      YAML.load(fixture('test/role_config/members.yml').read)['_all_environments']
    end
    let(:test_class) {
    	c = Class.new(User)
      c.class_eval do
        attr_accessor :request, :flash, :session
        include Cul::Omniauth::Users::ConfiguredRoles
      end
      c
    }

    before do
      Ability.instance_variable_set :@role_proxy_config, symbolize_hash_keys(rules)
    end

    after do
      Ability.instance_variable_set :@role_proxy_config, nil
    end

    subject { test_class.new }

    context "a role as ad-hoc members" do
      it 'should find memberships one level removed' do
        expect(subject.role? 'one_level').to be
      end
      it 'should find memberships several levels removed' do
        expect(subject.role? 'three_level').to be
      end
      it 'should still return false for other roles' do
        expect(subject.role? 'none_level').not_to be
      end
    end
  end
end