import { initializeApp } from "firebase/app";
import { getFirestore, doc, onSnapshot, setDoc } from "firebase/firestore";
import QueueProcessor from "../../../queue_processor.js";

const CAPTURE_PENDING_CODES = [
  "payment_is_capturing",
  "payment_capture_retrying",
  "payment_capture_unconfirmed",
];

async function listenToProcessingState({
  firebaseConfigs,
  documentReferencePath,
  onPaymentIsProcessing,
  onPaymentIsRetrying,
  onOrderIsProcessing,
  onOrderIsCompleted,
  onPaymentIsCapturing,
  onPaymentCaptureRetrying,
  onPaymentCaptureUnconfirmed,
  onOrderProcessFailed,
  onPaymentProcessFailed,
  onCompleted,
}) {
  const app = initializeApp(firebaseConfigs);
  const db = getFirestore(app);

  const documentRef = doc(db, documentReferencePath);
  await setDoc(documentRef, { listening: true }, { merge: true });

  const queueProcessor = new QueueProcessor();

  onSnapshot(documentRef, (doc) => {
    let documentData = doc.data();

    let messageCode = documentData["message_code"];
    let orderState = documentData["order_state"];
    let paymentState = documentData["payment_state"];
    let processing = documentData["processing"] === true;
    let reasonCode = documentData["reason_code"];
    let reasonMessage = documentData["reason_message"];

    if (window.parent !== window) {
      window.parent.postMessage(messageCode, "*");
    }

    // A pre-auth order completes on the hold, before the money is captured, so it isn't a success yet:
    // the server sends these capture codes until PaymentCapturerJob reports order_is_completed.
    let orderCompleted =
      orderState === "complete" && !CAPTURE_PENDING_CODES.includes(messageCode);
    if (orderCompleted) {
      queueProcessor.queueStateChange({
        minDelayInMs: 1500,
        callback: async () => {
          await onCompleted(
            orderState,
            paymentState,
            reasonCode,
            reasonMessage,
          );
        },
      });
      return;
    }

    switch (messageCode) {
      case "payment_is_processing":
        queueProcessor.queueStateChange({
          minDelayInMs: 1500,
          callback: async () => {
            await onPaymentIsProcessing(
              orderState,
              paymentState,
              processing,
              reasonCode,
              reasonMessage,
            );
          },
        });
        break;
      case "payment_is_retrying":
        queueProcessor.queueStateChange({
          minDelayInMs: 1500,
          callback: async () => {
            await onPaymentIsRetrying(
              orderState,
              paymentState,
              processing,
              reasonCode,
              reasonMessage,
            );
          },
        });
        break;
      case "order_is_processing":
        queueProcessor.queueStateChange({
          minDelayInMs: 1500,
          callback: async () => {
            await onOrderIsProcessing(
              orderState,
              paymentState,
              processing,
              reasonCode,
              reasonMessage,
            );
          },
        });
        break;
      case "order_is_completed":
        queueProcessor.queueStateChange({
          minDelayInMs: 1500,
          callback: async () => {
            await onOrderIsCompleted(
              orderState,
              paymentState,
              processing,
              reasonCode,
              reasonMessage,
            );
          },
        });
        break;
      case "payment_is_capturing":
        queueProcessor.queueStateChange({
          minDelayInMs: 1500,
          callback: async () => {
            // Optional: pages built before this message existed don't pass it.
            await onPaymentIsCapturing?.(
              orderState,
              paymentState,
              processing,
              reasonCode,
              reasonMessage,
            );
          },
        });
        break;
      case "payment_capture_retrying":
        queueProcessor.queueStateChange({
          minDelayInMs: 1500,
          callback: async () => {
            await onPaymentCaptureRetrying?.(
              orderState,
              paymentState,
              processing,
              reasonCode,
              reasonMessage,
            );
          },
        });
        break;
      case "payment_capture_unconfirmed":
        queueProcessor.queueStateChange({
          minDelayInMs: 1500,
          callback: async () => {
            await onPaymentCaptureUnconfirmed?.(
              orderState,
              paymentState,
              processing,
              reasonCode,
              reasonMessage,
            );
          },
        });
        break;
      case "order_process_failed":
        queueProcessor.queueStateChange({
          minDelayInMs: 1500,
          callback: async () => {
            await onOrderProcessFailed(
              orderState,
              paymentState,
              processing,
              reasonCode,
              reasonMessage,
            );
          },
        });
        break;
      case "payment_process_failed":
        queueProcessor.queueStateChange({
          minDelayInMs: 1500,
          callback: async () => {
            await onPaymentProcessFailed(
              orderState,
              paymentState,
              processing,
              reasonCode,
              reasonMessage,
            );
          },
        });
        break;
      default:
        break;
    }
  });
}

window.listenToProcessingState = listenToProcessingState;
