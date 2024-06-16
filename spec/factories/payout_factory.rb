FactoryBot.define do
  factory :payout, class: Spree::Payout do
    payout_profile {|p| p.association(:payway_payout_profile) }
    line_item {|p| p.association(:line_item) }
    payment {|p| p.association(:payment) }
  end
end
