require 'rails_helper'

describe Person do
  let(:person) { create(:person) }

  describe 'validation' do
    it 'has a valid factory' do
      expect(build(:person)).to be_valid
    end
  end

  describe 'association' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:reactions)}
  end
end
