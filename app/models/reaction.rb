class Reaction < ApplicationRecord
  belongs_to :reactionable, polymorphic: true
  belongs_to :person
  KINDS = [ 'like', 'love', 'haha', 'wow', 'sad', 'angry']

  def self.per_kind(kind)
    find_by(name: kind)
  end

  def self.haha
    where(name: 'haha')
  end

  def self.angry
    where(name: 'angry')
  end

  def self.like
    where(name: 'like')
  end

  def self.love
    where(name: 'love')
  end

  def self.wow
    where(name: 'wow')
  end

  def self.sad
    where(name: 'sad')
  end
end
