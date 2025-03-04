import { initializeApp } from "firebase/app";
import { getFirestore, doc, onSnapshot, setDoc } from "firebase/firestore";

async function listenToProcessingState({
  firebaseConfigs,
  orderNumber,
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

  const currentDate = new Date().toISOString().split("T")[0];

  const documentRef = doc(db, "statuses", "cart", currentDate, orderNumber);
  await setDoc(documentRef, { listening: true }, { merge: true });

  onSnapshot(documentRef, (doc) => {
    let documentData = doc.data();

    let orderState = documentData["order_state"];
    let paymentState = documentData["payment_state"];
    let messageCode = documentData["message_code"];
    let logMessage = documentData["log_message"];

    let orderCompleted = orderState === "complete";
    if (orderCompleted) {
      onCompleted(orderState, paymentState);
      return;
    }

    switch (messageCode) {
      case "payment_is_processing":
        onPaymentIsProcessing(orderState, paymentState, logMessage);
        break;
      case "order_is_processing":
        onOrderIsProcessing(orderState, paymentState, logMessage);
        break;
      case "order_is_completed":
        onOrderIsCompleted(orderState, paymentState, logMessage);
        break;
      case "order_process_failed":
        onOrderProcessFailed(orderState, paymentState, logMessage);
        break;
      case "payment_is_refunded":
        onPaymentIsRefunded(orderState, paymentState, logMessage);
        break;
      case "payment_process_failed":
        onPaymentProcessFailed(orderState, paymentState, logMessage);
        break;
      default:
        break;
    }
  });
}

window.listenToProcessingState = listenToProcessingState;
