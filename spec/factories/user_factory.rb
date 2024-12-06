FactoryBot.define do
  factory :organizer, parent: :user do
    spree_roles { [Spree::Role.find_by(name: 'organizer') || create(:role, name: 'organizer')] }
  end
  factory :ticket_seller_user, parent: :user do
    spree_roles { [Spree::Role.find_by(name: 'ticket_seller') || create(:role, name: 'ticket_seller')] }
  end
end