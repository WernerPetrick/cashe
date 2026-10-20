# Be sure to restart your server when you modify this file.

# Filter sensitive parameters from logs. Location parameters are on this list
# because raw coordinates must never be logged (CLAUDE.md privacy rules).
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  :latitude, :longitude, :near, :accuracy_m
]
