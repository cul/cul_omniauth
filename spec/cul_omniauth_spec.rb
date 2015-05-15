require 'spec_helper'

describe Cul::Omniauth do
  it do
    expect(Cul::Omniauth).to be_a Module
  end
  describe Cul::Omniauth::FailureApp do
    it "should isolate provider in subclasses" do
      app1 = Cul::Omniauth::FailureApp.for(:foo)
      app2 = Cul::Omniauth::FailureApp.for(:bar)
      app3 = app1.for(:lol)
      app4 = app1.for
      app5 = Cul::Omniauth::FailureApp.for
      expect(app1.provider).to eql(:foo)
      expect(app2.provider).to eql(:bar)
      expect(app3.provider).to eql(:lol)
      expect(app4.provider).to eql(:foo)
      # test the default
      expect(app5.provider).to eql(:saml)
    end
  end
end
