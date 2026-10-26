async function requestProcessPayment({
  params,
  url,
  maxRetries = 5,
  retryDelayMs = 1000,
}) {
  let attempt = 0;
  const delay = () =>
    new Promise((resolve) => setTimeout(resolve, retryDelayMs));

  while (attempt < maxRetries) {
    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document
            .querySelector('meta[name="csrf-token"]')
            .getAttribute("content"),
        },
        body: JSON.stringify({ ...params, internal_client: "true" }),
      });

      if (!response.ok) {
        throw new Error(`Request failed with status: ${response.status}`);
      }

      console.log("Request succeeded:", await response.json());
      break;
    } catch (error) {
      attempt++;
      console.error(`Attempt ${attempt} failed: ${error.message}`);

      if (attempt === maxRetries) {
        console.error("Max retries reached. Request failed.");
      } else {
        console.log("Retrying...");
        await delay();
      }
    }
  }
}

window.requestProcessPayment = requestProcessPayment;
