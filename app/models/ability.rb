class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
    user_pages = Page.all.select{ |page| page.pages_users.include? user }
    can :manage, Page
    can :manage, Post, page_id: user_pages
    can :manage, Reaction, page_id: user_pages
  end
end
