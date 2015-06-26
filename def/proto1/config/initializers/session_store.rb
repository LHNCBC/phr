## Be sure to restart your server when you modify this file.
#Proto1::Application.config.session_store :cookie_store, key: '_proto1_session'

## Use the database for sessions instead of the cookie-based default,
## which shouldn't be used to store highly confidential information
## (create the session table with "rails generate session_migration")
#Proto1::Application.config.session_store :active_record_store

# set up a secret for generating an integrity hash for cookie session data
Proto1::Application.config.session_store :active_record_store, {
    :key => "_phr_session",
    # Generate a new secret each time we start up.  The has the drawback of
    # invalidating existing sessions, but protects us against accidentally
    # sending our secret key out when we share code.
    #:secret => `/depot/packages/ruby/bin/rake secret`,
    #:secret => DEPOT_MODE ? `/depot/packages/ruby1.9/bin/rake secret` :
    :secret => PUBLIC_SYSTEM ? `#{Rails.root.join('../bin/rake')} secret` :
        '5d97e405520ae76ec6df1b34e71a49e3bcbf243e612ebdb76e7a1be06ce344341ac47f18801c892a80e91d7d3c88cf204abc8428513a7c085626b255c7738ab2',
    # Block javascript from reading session cookie
    :httpsonly => true,
    # cookie sent over SSL
    :secure => true
}
