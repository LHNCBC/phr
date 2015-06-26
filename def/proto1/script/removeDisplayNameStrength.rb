#! /proj/def/bin/ruby
# A ruby script for processing the RxTerms file to collapse some DISPLAY_NAMES
# that include the strength.

# Usage:  ruby removeDisplayNameStrength.rb [RxTerms file]
# Output:  The revised RxTerms file (to STDOUT)
#          Changes needing review are output to STDERR.
#
# Note:  There is test code for this script, in
# test/removeDisplayNameStrengthTest.rb.  If you change this script, be sure
# run and/or update the tests.

# The following is the set of changes that has been manually reviewed
# and approved (by Kin Wah).  The keys are the new strings; the values
# are the array of old strings.
#require 'rubygems'
#require 'ruby-debug'

GOOD_CHANGES_FILE = File.join(File.dirname(__FILE__),
   'removeDisplayNameStrength.yaml')
require 'yaml'
GOOD_CHANGES = YAML.load(File.read(GOOD_CHANGES_FILE))

# A list of drug names which should not be changed.  (If a drug name
# contains one of these strings, it will not be changed.)
DO_NOT_CHANGE = ['NOVOLOG', 'NOVOLIN', 'HUMULIN', 'HUMALOG']

TTY_COL = 2
DISPLAY_NAME_COL = 7
STRENGTH_COL = 10
NEW_DOSE_FORM_COL = 9
RETIRED_COL = 13

STRENGTH_VAL_SEP_CHARS = ['/', '-']
STRENGTH_VAL_SEP_REGEX = Regexp.new(STRENGTH_VAL_SEP_CHARS.join('|'))
STRENGTH_VAL_PAT = "(\\d[\\d\\.#{STRENGTH_VAL_SEP_CHARS.join}]+)"
STRENGTH_VAL_REGEX = Regexp.new(STRENGTH_VAL_PAT)
DISPLAY_NAME_PAT =
  '\\A(.*) '+STRENGTH_VAL_PAT+'(-[A-Z][^\\sa-z]+)?( [^\\d]*)?( \\([^\\)]+\\))\\z'
DISPLAY_NAME_REGEX = Regexp.new(DISPLAY_NAME_PAT)
DO_NOT_CHANGE_REGEX = Regexp.new(DO_NOT_CHANGE.join('|'))

# A set of lowercased generic drug names from the data file being edited
require 'set'
@generic_names_lc = Set.new

# Override standard to_yaml for a hash so that the keys are sorted.
# Taken from: http://snippets.dzone.com/posts/show/5811
class Hash
  # Replacing the to_yaml function so it'll serialize hashes sorted (by their keys)
  #
  # Original function is in /usr/lib/ruby/1.8/yaml/rubytypes.rb
  def to_yaml( opts = {} )
    YAML::quick_emit( object_id, opts ) do |out|
      out.map( taguri, to_yaml_style ) do |map|
        sort.each do |k, v|   # <-- here's my addition (the 'sort')
          map.add( k, v )
        end
      end
    end
  end
end


# Examines the RxTerms data and detects opportunities to remove the display
# name strength.  A data structure is returned (a hash of new display names to
# an array of data about the corresponding changed lines) that can be
# analyzed in further processing to decide which changes should be made.
# Lines that are not candidates for revision are written to STDOUT.
#
# Parameters:
# * file_data - the parsed data from the file, as returned by read_file_data.
def detect_potential_revisions(file_data)
  revision_data = {}

  file_data.each do |fields|
    line_is_modified = false

    # See if the display name is in the form:
    #   Drug Name Strength-Units (Route)
    # We only want to do this for brand names (all caps).
    # The number(s) that we pick out for the strength should be in the
    # set of numbers in the strength field.
    # The number of numbers in the strength field should not be greater
    # than two.
    # Strength should start with a number and might have more numbers
    # separated by dashes.
    # Units should have more than one character, and not contain spaces
    # or lowercase letters.
    # The revised brand name should not be the same (disregarding case)
    # as a generic name.
    is_brand_name = fields[TTY_COL] == 'SBD' # TTY==SBD if brand name
    display_name = fields[DISPLAY_NAME_COL]
    if is_brand_name && display_name !~ DO_NOT_CHANGE_REGEX &&
        display_name =~ DISPLAY_NAME_REGEX
      name = $1
      strength = $2
      units = $3
      form_info = $4 ? $4 : '' # e.g. CHEWABLE, XR, etc.
      route = $5

      # If the units are 'WASH', don't change the line.
      # Also, if the form_info is not really form info, don't change the line.
      if (units != '-WASH' && !name.index('/') &&
            form_info.index(' HOUR ') != 0 && form_info.index(' + ') != 0 &&
            form_info.index(' WITH ') != 0)

        # Get the numbers in the strength field.
        if fields[STRENGTH_COL] =~ STRENGTH_VAL_REGEX
          s_field_val_str = $1
          s_field_vals =
            s_field_val_str.split(STRENGTH_VAL_SEP_REGEX).sort
          disp_field_strengths =
            strength.split(STRENGTH_VAL_SEP_REGEX).sort

          new_name_route = name + form_info + route
          if !@generic_names_lc.member?(new_name_route.downcase)
            # Save the data for this line and decide later about revising
            # it.
            line_is_modified = true
            new_name_route_data = revision_data[new_name_route]
            if !new_name_route_data
              new_name_route_data = []
              revision_data[new_name_route] = new_name_route_data
            end
            new_name_route_data << [fields.clone, disp_field_strengths,
              s_field_vals]
          end
        end
      end
    end
    
    if !line_is_modified
      puts fields.join('|')
    end
  end

  return revision_data
end # def detect_potential_revisions


# Returns true if the given changes have been previously approved.
#
# Parameters:
# * new_name - the new drug name
# * array_of_line_data - an array with one entry for each RxTerms line that
#   would be getting relabled as new_name.  Each entry is also an array, and
#   the first element of that array is the array of field data.
def changes_approved(new_name, array_of_line_data)
  good_old_names = GOOD_CHANGES[new_name]
  revision_okay = false
  is_new_changes = false
  if good_old_names
    candidate_names = []
    array_of_line_data.each do |data|
      fields = data[0]
      # Exclude data for retired lines so we don't end up with duplicates in
      # the list.  (Often lines are changed by retiring the old version and
      # making a new one.)
      candidate_names<<fields[DISPLAY_NAME_COL] if fields[RETIRED_COL]!='TRUE'
    end

    # Allow candidate_names to be a subset of good_old_names, because it might
    # be that some entries in good_old_names are retired, and we have above
    # excluded retired entries from candidate_names.
    good_old_names_set = Set.new(good_old_names)
    candidate_names_set = Set.new(candidate_names)
    revision_okay = candidate_names_set.subset?(good_old_names_set)
  end
  return revision_okay
end


# Processes the hash of revision data returned by detect_potential_revisions.
# Lines that are not suitable for revision are written as is to STDOUT, and
# lines that can be revised are written in their revised form to STDOUT.
#
# Parameters:
# * revision_data - the data structure returned by detect_potential_revisions
def process_revision_data(revision_data)
  # Now process the revision candidates and decide what to actually change
  new_changes = {} # a structure like GOOD_CHANGES
  revision_data.each do |new_name, array_of_line_data|
    # We need to check the strength values in the display name field,
    # and compare them with the strength values in the strength fields.
    # Each set of numbers in a display name field should exactly equal
    # the strength field values in its own line.
    revision_okay = true
    array_of_line_data.each_with_index do |data, name_index|
      display_field_strengths = data[1]
      strength_field_strengths = data[2]
      # In general, we require that the display field contain all the strength
      # values in the strength field.
      revision_okay = display_field_strengths == strength_field_strengths
      # However, if the strength field has two strength values, and the display
      # field has one, we allow the change if the display field's value is in
      # the strength field and does not appear in another strength field
      # for this drug (i.e., if it is a unique number.) 
      disp_field_strength = display_field_strengths[0]
      if !revision_okay && strength_field_strengths.length ==2 &&
          display_field_strengths.length == 1 &&
          strength_field_strengths.index(disp_field_strength)
        # Make sure the display field strength does not appear in the other
        # slightly different strength fields for this drug.  (Otherwise the
        # change would be confusing.)
        fields = data[0]
        strength_field = fields[STRENGTH_COL]
        revision_okay = true
        array_of_line_data.each_with_index do |other_data, other_name_index|
          if name_index != other_name_index &&
              other_data[0][STRENGTH_COL] != strength_field &&
              other_data[2].index(disp_field_strength)
            revision_okay = false
            break
          end
        end
      end
      break if !revision_okay
    end
    
    # Output the (possibly changed) lines
    # Warn about the new changes, if the changes have not been
    # previously approved.  Note that some changes that were previously
    # approved might not be good changes to make in subsequent releases,
    # so we can't use the GOOD_CHANGES has to test whether is a change is
    # good.
    need_to_warn = !revision_okay ||
      !changes_approved(new_name, array_of_line_data)
    new_changes[new_name] = [] if need_to_warn && revision_okay
    array_of_line_data.each do |data|
      fields = data[0]
      if revision_okay
        if need_to_warn
          STDERR.puts "Changing #{fields[DISPLAY_NAME_COL]} to #{new_name} "+
            "(form|strength = #{fields[NEW_DOSE_FORM_COL]}|"+
            "#{fields[STRENGTH_COL]})"
          new_changes[new_name] << fields[DISPLAY_NAME_COL]
        end
        fields[DISPLAY_NAME_COL] = new_name
      end
      puts fields.join('|')
    end
    new_changes[new_name].sort!.uniq! if need_to_warn && revision_okay # note: [].uniq! => nil, so run sort! first
  end # each revision_data entry

  if new_changes.size > 0 && !TEST_MODE
    STDERR.puts "If the above changes are okay, type 'approved' to have them"+
      " be made next time without the warning: "
    if (STDIN.gets.chomp == 'approved')
      File.open(GOOD_CHANGES_FILE, 'w') do |f|
        f.puts '# Created and maintained by removeDisplayNameStrength.rb'
        f.puts GOOD_CHANGES.merge(new_changes).to_yaml
        f.flush
      end
    end
  end
end # def process_revision_data



# Read the file and parses the fields.  In the process it populates
# the @generic_names_lc variable.
#
# Parameters:
# * file_name - the RxTerms data file
#
# Returns: An array, with one entry per file line (except the header row), where
# each entry is an array of the fields in the row.
def read_file_data(file_name)
  file_data = []
  File.open(file_name) do |file|
    begin
      while line = file.readline.chomp
        line_is_modified = false
        fields = line.split(/\|/, -1)
        file_data << fields
        if fields[TTY_COL] == 'SCD'
          @generic_names_lc << fields[DISPLAY_NAME_COL].downcase
        end
      end
    rescue EOFError
      # we're done
    end
  end
  return file_data
end

TEST_MODE = ARGV[1] == 'test_mode'
file_data = read_file_data(ARGV[0]) # also loads @generic_names_lc
revision_data = detect_potential_revisions(file_data)
process_revision_data(revision_data)
