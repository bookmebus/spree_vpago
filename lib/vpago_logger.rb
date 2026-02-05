module VpagoLogger
  def self.log(event:, data: nil)
    message = { event: event }
    message.merge!(data) if data

    Rails.logger.info(message.to_json)
  end

  def self.error(event:, data: nil)
    message = { event: event }
    message.merge!(data) if data

    Rails.logger.error(message.to_json)
  end
end
