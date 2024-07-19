FactoryBot.define do
  factory :payout, class: Spree::Payout do
    payout_profile {|p| p.association(:payway_payout_profile, :random) }
    payoutable {|p| p.association(:line_item) }
    payment {|p| p.association(:payment) }
  end
end
