require 'rails_helper'

describe User do
  let(:user) { create(:user) }

  describe 'validation' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end
  end

  describe 'association' do
    it { is_expected.to have_one(:person) }
    it { is_expected.to have_many(:pages_users).dependent(:destroy) }
    it { is_expected.to have_many(:pages).through(:pages_users).dependent(:destroy) }
  end

  describe '.find_for_auth' do
    let(:auth) do
      OmniAuth::AuthHash.new(provider:    'facebook',
                             info:        {
                               name:     'new FaceBook user name',
                               email:    'fb_user@example.com'
                             },
                             credentials: {
                               token:  'mock_token',
                               secret: 'mock_secret'
                             }
                            )
    end

    context 'user is not signed in' do
      context 'first visit to website' do
        before { @auth_user = User.find_for_auth(auth) }

        it 'initializes new user' do
          expect(@auth_user.new_record?).to be true
        end

        it 'sets name, email, username and password' do
          expect(@auth_user.email).to eq 'fb_user@example.com'
        end
      end
    end
  end

  describe '.omniauth_providers' do
    it 'contains facebook provider' do
      expect(User.omniauth_providers).to eq [:facebook]
    end
  end
end
