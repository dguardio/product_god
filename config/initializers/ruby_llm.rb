RubyLLM.configure do |config|
  # Retrieve credentials
  google_creds = Rails.application.credentials.dig(:google)

  # Handle case where user pasted "api_key:XYZ" as a string value
  api_key = if google_creds.is_a?(String) && google_creds.include?("api_key:")
              google_creds.split("api_key:").last.strip
            elsif google_creds.is_a?(Hash)
              google_creds[:api_key]
            end

  if api_key.present?
    # Set the Gemini API key directly
    config.gemini_api_key = api_key
    config.logger = Rails.logger
    config.logger.level = :error
  else
    Rails.logger.warn "RubyLLM: Google API Key not found in credentials."
  end
end
