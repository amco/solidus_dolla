require "dolla"
module Spree
  class Gateway::DollaCard < Spree::PaymentMethod::CreditCard
    TEST_VISA = ['4111111111111111', '4012888888881881', '4222222222222']
    TEST_MC   = ['5500000000000004', '5555555555554444', '5105105105105100']
    TEST_AMEX = ['378282246310005', '371449635398431', '378734493671000', '340000000000009']
    TEST_DISC = ['6011000000000004', '6011111111111117', '6011000990139424']

    VALID_CCS = ['1', TEST_VISA, TEST_MC, TEST_AMEX, TEST_DISC].flatten

    attr_accessor :test

    def gateway_class
      self.class
    end

    def generate_profile_id(success)
      record = true
      prefix = success ? 'Dolla' : 'FAIL'
      while record
        random = "#{prefix}-#{Array.new(6){ rand(6) }.join}"
        record = Spree::CreditCard.where(gateway_customer_profile_id: random).first
      end
      random
    end

    def create_profile(payment)
      dolla_payment = Dolla::PaymentStub.new(
        payment_id: payment.id,
        code: payment.number,
        amount: payment.amount.to_f,
        cvv: payment.source.verification_value,
        card_number: payment.source.number,
        card_expiration: Date.parse("#{payment.source.year}/#{payment.source.month}"),
        name: payment.order.bill_address.firstname,
        last_name: payment.order.bill_address.lastname,
        address: payment.order.bill_address.address1,
        email: payment.order.email,
        phone_number: payment.order.bill_address.phone,
        zip_code: payment.order.bill_address.zipcode
      )
      return if payment.source.has_payment_profile?
      # simulate the storage of credit card profile using remote service
      if success = VALID_CCS.include?(payment.source.number)
        payment.source.update_attributes(gateway_customer_profile_id: generate_profile_id(success))
      end
    end

    def purchase(_money, credit_card, _options = {})
      profile_id = credit_card.gateway_customer_profile_id
      if VALID_CCS.include?(credit_card.number) || (profile_id && profile_id.starts_with?('Dolla-'))
        ActiveMerchant::Billing::Response.new(true, 'Dolla Gateway: Forced success', {}, test: true, authorization: '12345', avs_result: { code: 'M' })
      else
        ActiveMerchant::Billing::Response.new(false, 'Dolla Gateway: Forced failure', message: 'Dolla Gateway: Forced failure', test: true)
      end
    end

    def credit(_money, _credit_card, _response_code, _options = {})
      ActiveMerchant::Billing::Response.new(true, 'Dolla Gateway: Forced success', {}, test: true, authorization: '12345')
    end

    def void(_response_code, _credit_card, _options = {})
      ActiveMerchant::Billing::Response.new(true, 'Dolla Gateway: Forced success', {}, test: true, authorization: '12345')
    end

    def try_void(_payment)
      ActiveMerchant::Billing::Response.new(true, 'Dolla Gateway: Forced success', {}, test: true, authorization: '12345')
    end

    def test?
      # Test mode is not really relevant with dolla gateway (no such thing as live server)
      true
    end

    def payment_profiles_supported?
      true
    end

    def actions
      %w(capture void credit)
    end

    def payment_source_class
      CreditCard
    end

    def card?
      true
    end

    def auto_capture?
      true
    end

    def method_type
      'dolla_card'
    end
  end
end
