module Vpago
  module AcledaMobile
    class Checkout < Base
      attr_accessor :error_message, :results

      def call
        @results = {
          play_store: acleda_play_store,
          app_store: acleda_app_store,
          acleda_ios_deeplink: acleda_ios_deeplink,
          acleda_android_deeplink: acleda_android_deeplink
        }
      end

      def acleda_app_store
        "https://apps.apple.com/us/app/acleda-unity-toanchet/id1196285236"
      end

      def acleda_play_store
        "market://details?id=com.domain.acledabankqr"
      end

      def acleda_ios_deeplink
        "ACLEDAmobile://?partner_id=#{partner_id}&payment_data=#{aes_encrypted_payment_data}"
      end

      def acleda_android_deeplink
        "market://com.domain.acledabankqr/app?partner_id=#{partner_id}&payment_data=#{aes_encrypted_payment_data}"
      end

      def hmac_encrypted_payment_data
        json_data = payment_data.to_json
        key = encryption_key

        encrypted_result = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), key, json_data))
        encrypted_result.delete!("\n")
        encrypted_result
      end

      def hmac_hash(message, key)
        OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), key, message)
      end

      def aes_encrypted_payment_data

        data = payment_data.to_json + "~" + hmac_encrypted_payment_data
        key = encryption_key
        iv = [key].pack("H*") ##hex2bin
        cipher = OpenSSL::Cipher.new('AES-256-CBC')
        cipher.encrypt

        cipher.key = pbkdf2_key
        cipher.iv = iv

        crypt = cipher.update(data) + cipher.final
        encrypted_result = Base64.encode64(crypt).delete("\n")
        encrypted_result.gsub("/", "acledabankSecurityTC") ##follow acleda encrypting guide
      end

      def payment_data
        {
          app_name: 'VTENH',
          payment_amount: amount_with_fee,
          payment_amount_ccy: 'USD',
          payment_purpose: 'VTENH Transaction',
          txn_ref: payment_number
        }
      end

      def pbkdf2_key
        pass = encryption_key
        salt = pass
        iter = 100
        key_len = 32
        key = OpenSSL::KDF.pbkdf2_hmac(pass, salt: salt, iterations: iter, length: key_len, hash: "sha1")
        key
      end
    end
  end
end
