require 'rails_helper'

describe Post do
  let(:post) { create(:post) }

  describe 'validation' do
    it 'has a valid factory' do
      expect(build(:post)).to be_valid
    end
  end

  describe 'association' do
    it { is_expected.to belong_to(:page) }
    it { is_expected.to have_many(:reactions).dependent(:destroy) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:page_id) }
    it { is_expected.to validate_presence_of(:object_id) }
    it { is_expected.to validate_uniqueness_of(:object_id) }
  end
end
