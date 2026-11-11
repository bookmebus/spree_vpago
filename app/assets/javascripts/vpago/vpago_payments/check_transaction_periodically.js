/**
 * Polls the transaction status endpoint until the payment succeeds, fails, or
 * the maximum polling duration is reached.
 *
 * @param {Object} options
 * @param {string} options.checkTransactionUrl
 * @param {Function} options.onSuccess
 * @param {Function} options.onFailure
 */
async function checkTransactionPeriodically({
  checkTransactionUrl,
  onSuccess,
  onFailure,
  maxDurationMs = 10 * 60 * 1000,
  pollIntervalMs = 5000,
}) {
  var shouldPoll = true;
  var intervalId;
  var startTime = Date.now();
  var pollCount = 0;

  console.log("[Vpago] Starting transaction status polling", {
    url: checkTransactionUrl,
    maxDurationMs,
    pollIntervalMs,
  });

  var pollStatus = function () {
    if (!shouldPoll) return;

    if (Date.now() - startTime >= maxDurationMs) {
      shouldPoll = false;
      console.warn(
        "[Vpago] Polling timeout reached after " + pollCount + " attempts",
      );
      if (intervalId) clearInterval(intervalId);
      onFailure("timeout");
      return;
    }

    pollCount++;
    var elapsedMs = Date.now() - startTime;
    console.log(
      "[Vpago] Poll attempt #" + pollCount + " (elapsed: " + elapsedMs + "ms)",
    );

    fetch(checkTransactionUrl, {
      method: "GET",
      headers: { Accept: "application/json" },
      credentials: "same-origin",
    })
      .then(function (response) {
        return response.json().then(function (body) {
          return { ok: response.ok, body: body };
        });
      })
      .then(function (result) {
        var status =
          result.body && result.body.status
            ? String(result.body.status)
            : "pending";

        console.log("[Vpago] Transaction status:", JSON.stringify(result.body));

        if (status === "success" || status === "failed") {
          shouldPoll = false;
          if (intervalId) clearInterval(intervalId);

          if (status === "success") onSuccess(status);
          if (status === "failed") onFailure(status);
        }
      })
      .catch(function (error) {
        console.error("[Vpago] Transaction status polling failed:", error);
      });
  };

  intervalId = window.setInterval(pollStatus, pollIntervalMs);
}

window.checkTransactionPeriodically = checkTransactionPeriodically;
