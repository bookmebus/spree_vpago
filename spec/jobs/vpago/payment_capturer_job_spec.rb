require 'spec_helper'

RSpec.describe Vpago::PaymentCapturerJob, type: :job do
  let(:order) { create(:order_with_line_items, state: :payment) }
  let(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order) }

  it 'is enqueued on the payment_processing queue' do
    expect {
      described_class.perform_later(payment.id)
    }.to have_enqueued_job(described_class)
      .with(payment.id)
      .on_queue('payment_processing')
  end

  describe '#perform' do
    context 'when capture action is available' do
      before do
        allow(payment).to receive(:actions).and_return(['capture'])
        allow(Spree::Payment).to receive(:find).with(payment.id).and_return(payment)
      end

      it 'calls capture! on the payment' do
        expect(payment).to receive(:capture!)
        described_class.perform_now(payment.id)
      end
    end

    # What Sidekiq does on a failure: the job raises, then the same job runs again later.
    context 'when a pre-auth capture fails and Sidekiq retries the job' do
      let(:payment_method) { create(:payway_v2_gateway, enable_pre_auth: true, preferred_public_key: 'public-key') }
      let(:payment) { create(:payway_v2_payment, order: order, payment_method: payment_method, state: 'pending') }
      let(:user_informer) { instance_double(Vpago::UserInformers::Firebase, order_is_completed: nil, payment_capture_retrying: nil) }

      before do
        order.update_columns(state: 'complete', completed_at: Time.current)
        allow(Vpago::UserInformers::Firebase).to receive(:new).and_return(user_informer)
        # Each perform loads a fresh gateway instance, so the sequence has to live outside the stub.
        calls = 0
        allow_any_instance_of(Spree::Gateway::PaywayV2).to receive(:capture) do
          calls += 1
          ActiveMerchant::Billing::Response.new(calls > 1, calls > 1 ? 'Payway Gateway: Captured' : 'Payway Gateway: Capture Failed', {})
        end
      end

      it 'calls the gateway again on the retry and captures' do
        expect { described_class.perform_now(payment.id) }.to raise_error(Spree::Core::GatewayError)
        expect(payment.reload.state).to eq 'pending'
        expect(user_informer).not_to have_received(:order_is_completed)

        described_class.perform_now(payment.id)

        expect(payment.reload.state).to eq 'completed'
        expect(user_informer).to have_received(:order_is_completed).with(processing: false).once
      end

      it 'tells the processing page the capture is retrying, then still raises for Sidekiq' do
        expect { described_class.perform_now(payment.id) }.to raise_error(Spree::Core::GatewayError)

        expect(user_informer).to have_received(:payment_capture_retrying).with(processing: true).once
      end

      it 'still raises the gateway error when that notification fails' do
        allow(user_informer).to receive(:payment_capture_retrying).and_raise(StandardError, 'firestore down')

        expect { described_class.perform_now(payment.id) }.to raise_error(Spree::Core::GatewayError)
      end

      it 'still tells the processing page when the capture landed but the notification failed' do
        payment.update_columns(state: 'completed')

        described_class.perform_now(payment.id)

        expect(user_informer).to have_received(:order_is_completed).with(processing: false)
      end
    end

    context 'when a capture without pre-auth fails' do
      let(:user_informer) { instance_double(Vpago::UserInformers::Firebase) }

      before do
        order.update_columns(state: 'complete', completed_at: Time.current)
        payment.update_columns(state: 'pending')
        allow(Vpago::UserInformers::Firebase).to receive(:new).and_return(user_informer)
        allow_any_instance_of(Spree::Gateway::PaywayV2).to receive(:capture)
          .and_return(ActiveMerchant::Billing::Response.new(false, 'Payway Gateway: Capture Failed', {}))
      end

      it 'raises without the pre-auth retrying message' do
        expect(user_informer).not_to receive(:payment_capture_retrying)

        expect { described_class.perform_now(payment.id) }.to raise_error(Spree::Core::GatewayError)
      end
    end

    context 'when capture action is not available' do
      before do
        allow(payment).to receive(:actions).and_return([])
        allow(Spree::Payment).to receive(:find).with(payment.id).and_return(payment)
      end

      it 'does not call capture!' do
        expect(payment).not_to receive(:capture!)
        described_class.perform_now(payment.id)
      end
    end
  end

  # Run by Sidekiq's retries-exhausted hook, which this gem's specs don't load (see Vpago::SidekiqRetryCallbacks).
  # Releasing the uniqueness lock needs the host app's activejob-uniqueness, so cm-market-server's spec covers it.
  describe '#give_up_capture' do
    let(:payment_method) { create(:payway_v2_gateway, enable_pre_auth: true, preferred_public_key: 'public-key') }
    let(:payment) { create(:payway_v2_payment, order: order, payment_method: payment_method, state: 'pending') }
    let(:user_informer) { instance_double(Vpago::UserInformers::Firebase, payment_capture_unconfirmed: nil) }

    before { allow(Vpago::UserInformers::Firebase).to receive(:new).and_return(user_informer) }

    it 'tells the processing page the payment is not confirmed' do
      described_class.new(payment.id).send(:give_up_capture)

      expect(user_informer).to have_received(:payment_capture_unconfirmed).with(processing: false)
    end
  end

  describe '#notify_capture_unconfirmed' do
    let(:payment_method) { create(:payway_v2_gateway, enable_pre_auth: true, preferred_public_key: 'public-key') }
    let(:payment) { create(:payway_v2_payment, order: order, payment_method: payment_method, state: 'pending') }
    let(:user_informer) { instance_double(Vpago::UserInformers::Firebase, payment_capture_unconfirmed: nil) }

    before { allow(Vpago::UserInformers::Firebase).to receive(:new).and_return(user_informer) }

    it 'tells the processing page the payment is not confirmed while it is still uncaptured' do
      described_class.new(payment.id).send(:notify_capture_unconfirmed)

      expect(user_informer).to have_received(:payment_capture_unconfirmed).with(processing: false)
    end

    it 'stays quiet when the capture succeeded and only a later step failed' do
      payment.update_columns(state: 'completed')

      described_class.new(payment.id).send(:notify_capture_unconfirmed)

      expect(user_informer).not_to have_received(:payment_capture_unconfirmed)
    end

    it 'stays quiet when the payment no longer exists' do
      described_class.new(0).send(:notify_capture_unconfirmed)

      expect(user_informer).not_to have_received(:payment_capture_unconfirmed)
    end
  end
end
