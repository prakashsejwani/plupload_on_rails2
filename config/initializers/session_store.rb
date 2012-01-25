# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_pulpload_rails2_session',
  :secret      => '48d190ecf6e99b22fc0fd9661da07d0dfb9b3e66e9f47c02f739a966c1ae009e7275647ecbeae7b4101b1bf2f5ec3c946b773c844843551379ee1f8204e988d1'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
