require 'rails_helper'

describe Page do
  let(:page) { create(:page) }

  describe 'validation' do
    it 'has a valid factory' do
      expect(build(:page)).to be_valid
    end
  end

  describe 'association' do
    it { is_expected.to have_many(:posts).dependent(:destroy) }
    it { is_expected.to have_many(:events).dependent(:destroy) }
    it { is_expected.to have_many(:reactions).dependent(:destroy) }
    it { is_expected.to have_many(:city_fans).dependent(:destroy) }
    it { is_expected.to have_many(:age_fans).dependent(:destroy) }
    it { is_expected.to have_many(:pages_users).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:pages_users).dependent(:destroy) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:object_id) }
    it { is_expected.to validate_uniqueness_of(:object_id) }
  end
end
