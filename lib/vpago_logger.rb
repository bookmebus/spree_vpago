# lib/vpago_logger.rb
module VpagoLogger
  def self.log(label:, data: nil)
    message = { label: label, data: safe_serialize(data) }
    start_time = Time.current
    Rails.logger.info(message.to_json)

    return unless block_given?

    # Capture the block's return value and return it to preserve existing behavior for callers expecting that value.
    block_result = yield

    message[:start_time] = start_time.iso8601(3)
    message[:duration_ms] = (Time.current - start_time) * 1000
    message[:result] = safe_serialize(block_result)
    Rails.logger.info(message.to_json)
    block_result
  end

  def self.error(label:, data: nil)
    message = {
      label: label,
      data: safe_serialize(data)
    }

    Rails.logger.error(message.to_json)
  end

  # Safely serializes objects for JSON logging.
  #
  # @param obj [Object] The object to serialize
  # @param depth [Integer] Internal parameter tracking recursion depth (max: 50)
  # @return [Object] A JSON-safe representation of the input object
  def self.safe_serialize(obj, depth: 0)
    return '[Max Depth Exceeded]' if depth > 50

    if obj.is_a?(Hash)
      obj.each_with_object({}) do |(k, v), memo|
        memo[safe_serialize(k, depth: depth + 1)] = safe_serialize(v, depth: depth + 1)
      end
    elsif obj.is_a?(Array)
      obj.map { |item| safe_serialize(item, depth: depth + 1) }
    elsif obj.is_a?(Date)
      obj.iso8601
    elsif obj.is_a?(Time) || obj.is_a?(DateTime) || obj.is_a?(ActiveSupport::TimeWithZone)
      obj.iso8601(3)
    elsif obj.is_a?(ActiveJob::Base)
      {
        job_class: obj.class.name,
        job_id: obj.job_id,
        arguments: safe_serialize(obj.arguments, depth: depth + 1)
      }
    elsif obj.respond_to?(:id)
      { class: obj.class.name, id: obj.id }
    else
      obj.to_s
    end
  end
end
