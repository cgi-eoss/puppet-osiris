require 'spec_helper'

#Puppet::Util::Log.level = :debug
#Puppet::Util::Log.newdestination(:console)

describe 'osiris::portal', :type => 'class' do
  it { should compile }
  it { should contain_class('osiris::portal') }
end
