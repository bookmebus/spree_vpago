require 'google/cloud/firestore'

module Vpago
  module UserInformers
    # order.tenant is available here but intentionally unused in #firebase_credentials —
    # processing.html.erb reads this same document path via the still-global
    # firebase_web_config Web SDK config, so this can't move to order.tenant's project
    # until that view also goes per-tenant.
    class Firebase
      attr_accessor :order

      def initialize(order)
        @order = order
      end

      def payment_is_processing(processing:) = notify(:payment_is_processing, processing)
      def payment_is_retrying(processing:) = notify(:payment_is_retrying, processing)
      def order_is_processing(processing:) = notify(:order_is_processing, processing)
      def order_is_completed(processing:) = notify(:order_is_completed, processing)
      def order_process_failed(processing:, reason_code:, reason_message: nil) = notify(:order_process_failed, processing, reason_code, reason_message)
      def payment_process_failed(processing:, reason_code:, reason_message: nil) = notify(:payment_process_failed, processing, reason_code, reason_message)

      def notify(message_code, processing, reason_code = nil, reason_message = nil)
        order.reload

        data = {
          processing: processing,
          message_code: message_code,
          reason_code: reason_code,
          reason_message: reason_message,
          order_state: order.state,
          payment_state: order.payment_state,
          updated_at: Time.current
        }.compact

        firestore_reference.set(data, merge: true)
        firestore_reference.col('histories').doc(message_code).set(data)
      end

      def firestore_reference
        order_created_date = order.created_at.strftime('%Y-%m-%d')
        @firestore_reference ||= firestore.col('statuses')
                                          .doc('cart')
                                          .col(order_created_date)
                                          .doc(order.number)
      end

      def document_reference_path
        firestore_reference.path.split('/documents').last
      end

      def firestore
        @firestore ||= firebase_credentials.firestore
      end

      def firebase_credentials
        @firebase_credentials ||= SpreeCmCommissioner::FirebaseCredentialsResolver.resolve(tenant: nil)
      end
    end
  end
end
