module Vpago
  module Payway
    CARD_TYPE_ABAPAY = 'abapay'.freeze
    CARD_TYPE_ABAPAY_KHQR = 'abapay_khqr'.freeze
    CARD_TYPE_CARDS = 'cards'.freeze
    CARD_TYPE_WECHAT = 'wechat'.freeze
    CARD_TYPE_ALIPAY = 'alipay'.freeze

    CARD_TYPES = [CARD_TYPE_ABAPAY, CARD_TYPE_ABAPAY_KHQR, CARD_TYPE_CARDS, CARD_TYPE_WECHAT, CARD_TYPE_ALIPAY].freeze
  end
end
