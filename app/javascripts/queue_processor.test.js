import { expect } from "chai";
import QueueProcessor from "./queue_processor.js";

describe("QueueProcessor", () => {
  let queueProcessor;
  let minDelayInMs = 100;

  beforeEach(() => {
    queueProcessor = new QueueProcessor();
  });

  it("should initially have an empty queue and not be processing", () => {
    expect(queueProcessor.queues).to.have.lengthOf(0);
    expect(queueProcessor.processing).to.equal(false);
  });

  it("should run queue 1 by 1 while keep min delay 100", async () => {
    let timeToProcess = 50;

    const mockCallback = () =>
      new Promise((resolve) => setTimeout(resolve, timeToProcess));

    queueProcessor.queueStateChange({
      callback: mockCallback,
      minDelayInMs: minDelayInMs,
    });

    queueProcessor.queueStateChange({
      callback: mockCallback,
      minDelayInMs: minDelayInMs,
    });

    queueProcessor.queueStateChange({
      callback: mockCallback,
      minDelayInMs: minDelayInMs,
    });

    expect(queueProcessor.queues).to.have.lengthOf(2);
    expect(queueProcessor.processing).to.equal(true);

    await new Promise((resolve) => setTimeout(resolve, minDelayInMs * 3 + 4)); // +4ms for buffer

    expect(queueProcessor.queues).to.have.lengthOf(0);
    expect(queueProcessor.processing).to.equal(false);
  });

  describe("when process take less than the delay", () => {
    it("should process and wait for remaining delay", async () => {
      let timeToProcess = 50;

      const mockCallback = () =>
        new Promise((resolve) => setTimeout(resolve, timeToProcess));

      queueProcessor.queueStateChange({
        callback: mockCallback,
        minDelayInMs: minDelayInMs,
      });

      expect(queueProcessor.queues).to.have.lengthOf(0);
      expect(queueProcessor.processing).to.equal(true);

      await new Promise((resolve) => setTimeout(resolve, minDelayInMs + 1)); // +1ms for buffer

      expect(queueProcessor.queues).to.have.lengthOf(0);
      expect(queueProcessor.processing).to.equal(false);
    });
  });

  describe("when process take longer than the delay", () => {
    it("should process and not wait for delay", async () => {
      let timeToProcess = 200;

      const mockCallback = () =>
        new Promise((resolve) => setTimeout(resolve, timeToProcess));

      queueProcessor.queueStateChange({
        callback: mockCallback,
        minDelayInMs: minDelayInMs,
      });

      expect(queueProcessor.queues).to.have.lengthOf(0);
      expect(queueProcessor.processing).to.equal(true);

      await new Promise((resolve) => setTimeout(resolve, timeToProcess + 1)); // +1ms for buffer
      expect(queueProcessor.processing).to.equal(false);
    });
  });
});
