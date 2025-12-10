window.initPaymentProcessingListener = async function (
  firebaseConfigs,
  documentReferencePath,
  successUrl
) {
  function log(status, processing, reasonCode, reasonMessage) {
    console.log(`Status: ${status}`);
    console.log(`Reason Code: ${reasonCode}`);
    console.log(
      `Processing: ${processing ? "Processing..." : "No more process."}`
    );
    console.log(`Reason Message: ${reasonMessage}`);
  }

  window.listenToProcessingState({
    firebaseConfigs,
    documentReferencePath,

    onPaymentIsProcessing(
      orderState,
      paymentState,
      processing,
      reasonCode,
      reasonMessage
    ) {
      log("Payment is processing", processing, reasonCode, reasonMessage);
    },

    onPaymentIsRetrying(
      orderState,
      paymentState,
      processing,
      reasonCode,
      reasonMessage
    ) {
      log("Payment is retrying", processing, reasonCode, reasonMessage);
    },

    onOrderIsProcessing(
      orderState,
      paymentState,
      processing,
      reasonCode,
      reasonMessage
    ) {
      log("Order is processing", processing, reasonCode, reasonMessage);
    },

    onOrderIsCompleted(
      orderState,
      paymentState,
      processing,
      reasonCode,
      reasonMessage
    ) {
      log("Order is completed", processing, reasonCode, reasonMessage);
    },

    onOrderProcessFailed(
      orderState,
      paymentState,
      processing,
      reasonCode,
      reasonMessage
    ) {
      log("Order process failed", processing, reasonCode, reasonMessage);
    },

    onPaymentProcessFailed(
      orderState,
      paymentState,
      processing,
      reasonCode,
      reasonMessage
    ) {
      log("Payment process failed", processing, reasonCode, reasonMessage);
    },

    onCompleted(
      orderState,
      paymentState,
      processing,
      reasonCode,
      reasonMessage
    ) {
      log(
        "Completed — redirecting to success URL",
        processing,
        reasonCode,
        reasonMessage
      );
      window.location.href = successUrl;
    },
  });
};
