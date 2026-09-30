export default class QueueProcessor {
  constructor() {
    this.queues = [];
    this.processing = false;
  }

  queueStateChange({ callback, minDelayInMs = 1000 }) {
    this.queues.push({ callback, minDelayInMs });
    if (!this.processing) this.#processQueue();
  }

  async #processQueue() {
    if (this.queues.length === 0) {
      this.processing = false;
      return;
    }

    this.processing = true;
    const { callback, minDelayInMs } = this.queues.shift();
    const startTime = Date.now();

    await callback();

    const elapsedTime = Date.now() - startTime;
    if (elapsedTime < minDelayInMs) {
      await new Promise((resolve) =>
        setTimeout(resolve, minDelayInMs - elapsedTime)
      );
    }

    this.#processQueue();
  }
}
