module Vpago
  class VattanacMiniAppDataHandler
    def decrypt_data(data)
      encrypted_data, signature = data.to_s.split('.', 2)
      
      return nil unless Vpago::RsaHandler.new(public_key: vattanac_public_key).verify(encrypted_data, signature)

      decrypted = Vpago::AesEncrypter.decrypt(encrypted_data, aes_key)
      JSON.parse(decrypted) rescue nil
   
    end

    def encrypted_data(payload)
      json_payload = payload.to_json
      encrypted_data = Vpago::AesEncrypter.encrypt(json_payload, aes_key)
      rsa_service = Vpago::RsaHandler.new(private_key: bookmeplus_private_key)
      signed_data = rsa_service.sign(encrypted_data)
      signed_data
    end

    def vattanac_public_key 
      ENV['VATTANAC_PUBLIC_KEY'].presence || Rails.application.credentials.vattanac.public_key
    end

    def bookmeplus_private_key 
      ENV['BOOKMEPLUS_PRIVATE_KEY'].presence  || Rails.application.credentials.bookmeplus.private_key
    end

    def aes_key
     ENV['VATTANAC_AES_SECRET_KEY'].presence || Rails.application.credentials.vattanac.aes_secret_key
    end
  end
end