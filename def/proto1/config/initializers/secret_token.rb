# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# (Refer to the setting for :secret in session_store.rb) 
#Proto1::Application.config.secret_token = DEPOT_MODE ? "/depot/packages/ruby1.9/bin/rake secret" : 
Proto1::Application.config.secret_token = PUBLIC_SYSTEM ? `#{Rails.root.join('../bin/rake')} secret` : 
  '63e2bba242f2112e2e2d50d2d5c377cfeffeb871ba9cd1ef53e35a2461ab11cf271722050dd7b399deffb54b7989331cbc3b2b5df6526680765dcfc82f905414'
#Proto1::Application.config.secret_key_base = PUBLIC_SYSTEM ? `#{Rails.root.join('../bin/rake')} secret` :
#  '63e2bba242f2112e2e2d50d2d5c377cfeffeb871ba9cd1ef53e35a2461ab11cf271722050dd7b399deffb54b7989331cbc3b2b5df6526680765dcfc82f905414'
