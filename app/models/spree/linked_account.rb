module Spree
  class LinkedAccount < Base
    belongs_to :user, class_name: 'Spree::User'
  end
end
