require "dolla"
module Spree
  class Gateway::DollaCard < Spree::PaymentMethod::CreditCard
    attr_accessor :test

    def gateway_class
      self.class
    end

    def luhn_checksum(card_number)
      return true if Rails.env.staging? || Rails.env.development?
      return false unless card_number.present?
      odd = true

      checksum = card_number.reverse.split(//).map(&:to_i).map do |digit|
        digit *= 2 if odd = !odd
        digit > 9 ? digit - 9 : digit
      end.sum

      checksum % 10 == 0
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

      if success = luhn_checksum(payment.source.number)
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

    def test?
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
