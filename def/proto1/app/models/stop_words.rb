# Provides methods for retrieving the stop word list.
#
require 'set'
class StopWords
  # The list of stop words
  @@FULL_LIST = nil

  # A set containing the words in @@FULL_LIST
  @@STOP_WORD_SET = nil

  # Returns the list of stop words.  Do not change the returned value.
  def self.get_all_stop_words
    if (@@FULL_LIST.nil?)
      rtn = [] # Ferret::Analysis::FULL_ENGLISH_STOP_WORDS.clone
      # (We decided that in our context we do not need standard stop words.)
      
      File.open('config/salts.txt') do |file|
        file.each_line do |line|
          rtn.push(line.chop.strip) # chop to remove newline
        end
      end

      rtn.sort!
      @@FULL_LIST = rtn
    else
      rtn = @@FULL_LIST
    end
    
    rtn
  end

  
  # Returns true if the given word is in the stop word list.
  def self.is_stop_word(word)
    if @@STOP_WORD_SET.nil?
      @@STOP_WORD_SET = Set.new(get_all_stop_words)
    end
    return @@STOP_WORD_SET.member?(word.downcase)
  end
end

