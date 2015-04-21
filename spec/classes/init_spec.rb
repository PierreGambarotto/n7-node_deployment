require 'spec_helper'
describe 'node_deployment' do

  context 'with defaults for all parameters' do
    it { should contain_class('node_deployment') }
  end
end
