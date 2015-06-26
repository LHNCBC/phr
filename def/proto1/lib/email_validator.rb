# This class creates a validator to be used to validate email addresses.
# This was copied from lindsaar.net, at
#    http://lindsaar.net/2010/3/31/validates_rails_3_awesome_is_true
#
# This allows us to access this via a validator in a model class.  See the
# User model class for an example.
#
# Although email addresses are often validated with a single regexp, this
# validates more complex addresses.  So I used this one.  (Although I did
# change the error message).
#
# but I don't seem to be able to get this to work - at least not
# from the User model class.
#
# class EmailValidator < ActiveModel::EachValidator <-- we're not at the version
#                                                   of rails that supports this
class EmailValidator 
  #EmailAddress = begin

  def self.email_address_format(addr)
    qtext = '[^\\x0d\\x22\\x5c\\x80-\\xff]'
    dtext = '[^\\x0d\\x5b-\\x5d\\x80-\\xff]'
    atom = '[^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-' +
      '\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\xff]+'
    quoted_pair = '\\x5c[\\x00-\\x7f]'
    domain_literal = "\\x5b(?:#{dtext}|#{quoted_pair})*\\x5d"
    quoted_string = "\\x22(?:#{qtext}|#{quoted_pair})*\\x22"
    domain_ref = atom
    sub_domain = "(?:#{domain_ref}|#{domain_literal})"
    word = "(?:#{atom}|#{quoted_string})"
    domain = "#{sub_domain}(?:\\x2e#{sub_domain})*"
    local_part = "#{word}(?:\\x2e#{word})*"
    addr_spec = "#{local_part}\\x40#{domain}"
    pattern = /\A#{addr_spec}\z/
    return addr =~ pattern
  end

  def validate_each(record, attribute, value)
    unless value =~ EmailAddress
      record.errors[attribute] << (options[:message] ||
                                   "The email address entered is not valid")
    end
  end

end
