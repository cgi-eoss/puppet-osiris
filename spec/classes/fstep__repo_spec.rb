require 'spec_helper'

#Puppet::Util::Log.level = :debug
#Puppet::Util::Log.newdestination(:console)

describe 'osiris::repo', :type => 'class' do
  it { should compile }
  it { should contain_class('osiris::repo') }
  it { should contain_class('osiris::repo::yum') }
  it { should contain_yumrepo('osiris').with_baseurl('file:///path/to/repo') }
end
