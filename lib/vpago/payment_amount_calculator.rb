module Vpago
  module PaymentAmountCalculator
    def amount
      @payment.amount
    end
    
    def amount_with_fee
      "%.2f" % ( amount + transaction_fee )
    end

    def transaction_fee_fix
      @payment.payment_method.preferences[:transaction_fee_fix].to_f
    end
  
    def transaction_fee_percentage
      @payment.payment_method.preferences[:transaction_fee_percentage].to_f
    end
  
    def transaction_fee
      transaction_fee_fix + (amount * transaction_fee_percentage ) / 100
    end
  end
end
