import { initializeApp } from "firebase/app";
import { getFirestore, doc, collection, onSnapshot, setDoc } from "firebase/firestore";
import QueueProcessor from "../../../queue_processor.js";

const CAPTURE_PENDING_CODES = [
  "payment_is_capturing",
  "payment_capture_retrying",
  "payment_capture_unconfirmed",
];

// A completion step (the order document's expected_steps) is over once its job reports either; the page
// doesn't wait on a failed one, since payment is already final by then.
const STEP_FINISHED_STATUSES = ["done", "failed"];

// Completion steps (e.g. seat assignment) only refine a paid booking and keep running after the user
// leaves, so a slow one must not hold them here.
const COMPLETION_STEPS_TIMEOUT_MS = 20000;

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
  onCompletionStepsPending,
  onOrderProcessFailed,
  onPaymentProcessFailed,
  onCompleted,
}) {
  const app = initializeApp(firebaseConfigs);
  const db = getFirestore(app);

  const documentRef = doc(db, documentReferencePath);
  await setDoc(documentRef, { listening: true }, { merge: true });

  const queueProcessor = new QueueProcessor();

  let orderData = null;
  let steps = {};
  let stepsTimer = null;
  let completed = false;

  const complete = () => {
    if (completed) return;
    completed = true;

    if (window.parent !== window) {
      window.parent.postMessage("order_is_completed", "*");
    }

    queueProcessor.queueStateChange({
      minDelayInMs: 1500,
      callback: async () => {
        await onCompleted(
          orderData["order_state"],
          orderData["payment_state"],
          orderData["reason_code"],
          orderData["reason_message"],
        );
      },
    });
  };

  // Success needs the order complete (capture landed) and every expected step finished. They arrive on
  // separate listeners -- each step is its own document, written only by its job -- so both re-check.
  const completeWhenReady = () => {
    if (completed || !isOrderCompleted(orderData)) return;

    let pendingSteps = (orderData["expected_steps"] ?? []).filter(
      (key) => !STEP_FINISHED_STATUSES.includes(steps[key]?.status),
    );
    if (pendingSteps.length === 0) return complete();

    queueProcessor.queueStateChange({
      minDelayInMs: 1500,
      callback: async () => {
        await onCompletionStepsPending?.(pendingSteps);
      },
    });
    stepsTimer ??= setTimeout(complete, COMPLETION_STEPS_TIMEOUT_MS);
  };

  onSnapshot(collection(documentRef, "steps"), (snapshot) => {
    steps = Object.fromEntries(snapshot.docs.map((d) => [d.id, d.data()]));
    completeWhenReady();
  });

  onSnapshot(documentRef, (doc) => {
    let documentData = doc.data();
    orderData = documentData;

    let messageCode = documentData["message_code"];
    let orderState = documentData["order_state"];
    let paymentState = documentData["payment_state"];
    let processing = documentData["processing"] === true;
    let reasonCode = documentData["reason_code"];
    let reasonMessage = documentData["reason_message"];

    if (isOrderCompleted(documentData)) {
      completeWhenReady();
      return;
    }

    if (window.parent !== window) {
      window.parent.postMessage(messageCode, "*");
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

// A pre-auth order completes on the hold, before the money is captured, so it isn't a success yet: the
// server sends these capture codes until PaymentCapturerJob reports order_is_completed.
function isOrderCompleted(data) {
  return (
    data?.["order_state"] === "complete" &&
    !CAPTURE_PENDING_CODES.includes(data["message_code"])
  );
}

window.listenToProcessingState = listenToProcessingState;
