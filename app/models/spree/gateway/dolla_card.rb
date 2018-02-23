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

    def purchase(_money, credit_card, _options = {})
      payment = _options[:originator]
      response = Dolla::PaymentStub.new(
        payment_id: payment.id,
        code: payment.number,
        amount: payment.amount.to_f,
        cvv: payment.source.verification_value,
        card_number: credit_card.number,
        card_expiration: Date.parse("#{credit_card.year}/#{credit_card.month}"),
        name: payment.order.bill_address.firstname,
        last_name: payment.order.bill_address.lastname,
        address: payment.order.bill_address.address1,
        email: payment.order.email,
        phone_number: payment.order.bill_address.phone,
        zip_code: payment.order.bill_address.zipcode
      ).pay!

      response_body = response.hash[:envelope][:body]

      # Checking if payment was with AMEX card
      if response_body[:ins_pago_amex_response]
        if response_body[:ins_pago_amex_response][:authorization_code] && response_body[:ins_pago_amex_response][:codigo_respuesta] == "0"
          ActiveMerchant::Billing::Response.new(true, 'Payment was successful', {}, test: true)
        else
          ActiveMerchant::Billing::Response.new(false, 'Dolla Gateway: Forced failure', message: response_body[:ins_pago_amex_response][:mensaje], test: true)
        end
      else
        if !response_body[:procesa_compra_ol_response][:procesa_compra_ol_return].nil?
          ActiveMerchant::Billing::Response.new(true, 'Payment was successful', {}, test: true)
        else
          ActiveMerchant::Billing::Response.new(false, 'Dolla Gateway: Forced failure', message: 'Dolla Gateway: Forced failure', test: true)
        end
      end
    end

    def test?
      true
    end

    def payment_profiles_supported?
      false
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
