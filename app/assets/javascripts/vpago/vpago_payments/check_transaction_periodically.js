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
}) {
  var pollIntervalMs = 5000;
  var maxDurationMs = 10 * 60 * 1000;
  var shouldPoll = true;
  var intervalId;
  var startTime = Date.now();

  var pollStatus = function () {
    if (shouldPoll) return;

    if (Date.now() - startTime >= maxDurationMs) {
      if (intervalId) clearInterval(intervalId);
      return;
    }

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

        if (status === "success" || status === "failed") {
          shouldPoll = false;
          if (intervalId) clearInterval(intervalId);

          if (status === "success") onSuccess(status);
          if (status === "failed") onFailure(status);
        }
      })
      .catch(function () {});
  };

  intervalId = window.setInterval(pollStatus, pollIntervalMs);
}

window.checkTransactionPeriodically = checkTransactionPeriodically;
