require 'rails_helper'

describe Reaction do
  let(:user) { create(:reaction) }

  describe 'validation' do
    it 'has a valid factory' do
      expect(build(:reaction)).to be_valid
    end
  end

  describe 'association' do
    it { is_expected.to belong_to(:reactionable) }
    it { is_expected.to belong_to(:person) }
    it { is_expected.to belong_to(:page) }
  end
end
