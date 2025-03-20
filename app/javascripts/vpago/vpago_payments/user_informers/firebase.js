import { initializeApp } from "firebase/app";
import { getFirestore, doc, onSnapshot, setDoc } from "firebase/firestore";

async function listenToProcessingState({
  firebaseConfigs,
  documentReferencePath,
  onPaymentIsProcessing,
  onOrderIsProcessing,
  onOrderIsCompleted,
  onOrderProcessFailed,
  onPaymentIsRefunded,
  onPaymentProcessFailed,
  onCompleted,
}) {
  const app = initializeApp(firebaseConfigs);
  const db = getFirestore(app);

  const documentRef = doc(db, documentReferencePath);
  await setDoc(documentRef, { listening: true }, { merge: true });

  onSnapshot(documentRef, (doc) => {
    let documentData = doc.data();

    let messageCode = documentData["message_code"];
    let orderState = documentData["order_state"];
    let paymentState = documentData["payment_state"];
    let processing = documentData["processing"] === true;
    let reasonCode = documentData["reason_code"];
    let reasonMessage = documentData["reason_message"];

    let orderCompleted = orderState === "complete";
    if (orderCompleted) {
      onCompleted(orderState, paymentState, reasonCode, reasonMessage);
      return;
    }

    switch (messageCode) {
      case "payment_is_processing":
        onPaymentIsProcessing(
          orderState,
          paymentState,
          processing,
          reasonCode,
          reasonMessage
        );
        break;
      case "order_is_processing":
        onOrderIsProcessing(
          orderState,
          paymentState,
          processing,
          reasonCode,
          reasonMessage
        );
        break;
      case "order_is_completed":
        onOrderIsCompleted(
          orderState,
          paymentState,
          processing,
          reasonCode,
          reasonMessage
        );
        break;
      case "order_process_failed":
        onOrderProcessFailed(
          orderState,
          paymentState,
          processing,
          reasonCode,
          reasonMessage
        );
        break;
      case "payment_is_refunded":
        onPaymentIsRefunded(
          orderState,
          paymentState,
          processing,
          reasonCode,
          reasonMessage
        );
        break;
      case "payment_process_failed":
        onPaymentProcessFailed(
          orderState,
          paymentState,
          processing,
          reasonCode,
          reasonMessage
        );
        break;
      default:
        break;
    }
  });
}

window.listenToProcessingState = listenToProcessingState;
