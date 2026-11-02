require 'spec_helper'

RSpec.describe Vpago::SidekiqRetryCallbacks do
  let(:calls) { [] }

  describe '.after_failed_attempt' do
    let(:job_class) do
      recorded = calls
      Class.new(ActiveJob::Base) do
        include Vpago::SidekiqRetryCallbacks

        after_failed_attempt ArgumentError, with: :on_failed

        define_method(:perform) { |fail_with| raise fail_with if fail_with }
        define_method(:on_failed) { recorded << [:failed, arguments] }
      end
    end

    it 'runs the handler, then re-raises so Sidekiq retries' do
      expect { job_class.perform_now(ArgumentError) }.to raise_error(ArgumentError)

      expect(calls).to eq [[:failed, [ArgumentError]]]
    end

    it 'ignores errors it was not declared for' do
      expect { job_class.perform_now(KeyError) }.to raise_error(KeyError)

      expect(calls).to be_empty
    end

    it 'skips the handler when the job succeeds' do
      job_class.perform_now(nil)

      expect(calls).to be_empty
    end

    it 'keeps the original error when the handler fails' do
      job_class.define_method(:on_failed) { raise 'firestore down' }

      expect { job_class.perform_now(ArgumentError) }.to raise_error(ArgumentError)
    end
  end

  describe '.after_retries_exhausted' do
    it 'does nothing without Sidekiq' do
      job_class = Class.new(ActiveJob::Base) { include Vpago::SidekiqRetryCallbacks }

      expect { job_class.after_retries_exhausted(with: :on_exhausted) }.not_to raise_error
    end

    context 'with Sidekiq' do
      let(:job_class) do
        recorded = calls
        Class.new(ActiveJob::Base) do
          include Vpago::SidekiqRetryCallbacks

          # Stands in for Sidekiq::Job::Options, which the host app's Sidekiq adds to ActiveJob.
          singleton_class.attr_reader :exhausted_block
          define_singleton_method(:sidekiq_retries_exhausted) { |&block| @exhausted_block = block }

          after_retries_exhausted with: :on_exhausted

          define_method(:on_exhausted) { recorded << [:exhausted, arguments] }
        end
      end

      it 'runs the handler with the job arguments unwrapped from the Sidekiq payload' do
        sidekiq_job = { 'wrapped' => 'SomeJob', 'args' => [job_class.new(42, 'x').serialize] }

        job_class.exhausted_block.call(sidekiq_job, StandardError.new)

        expect(calls).to eq [[:exhausted, [42, 'x']]]
      end
    end
  end
end
