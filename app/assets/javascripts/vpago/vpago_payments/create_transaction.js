/**
 * Calls our own server, which creates the bank transaction on the browser's
 * behalf and returns the bank's response as JSON.
 *
 * @param {Object} options
 * @param {string} options.url
 * @param {Function} options.onSuccess
 * @param {Function} options.onError
 */
async function createTransaction({ url, onSuccess, onError }) {
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document
          .querySelector('meta[name="csrf-token"]')
          .getAttribute("content"),
      },
    });
    const data = await response.json();

    if (!response.ok || data.error) {
      console.error("[Vpago] createTransaction failed:", JSON.stringify(data));
      onError(data);
      return;
    }

    onSuccess(data);
  } catch (error) {
    console.error("[Vpago] createTransaction request failed:", error);
    onError(error);
  }
}

window.createTransaction = createTransaction;
