#!/proj/def/bin/ruby
# This script takes two RxTermsIngredients files as arguments, and
# produces a tab-delimited table of the changes to the list of
# ingredients.  This comparison is done against the CUIs, not the
# strings.

file1 = ARGV[0]
file2 = ARGV[1]

puts "#{File.basename(file1)}\t#{File.basename(file2)}\tING_RXCUI\tIngredient"


# Read the file and parses the fields.
#
# Parameters:
# * file_name - the RxTermsIngredient data file
#
# Returns: A map of ingredient RxCUIs to ingredient names
def read_file_data(file_name)
  cui_to_name = {}
  File.open(file_name) do |file|
    first_line = true
    begin
      while line = file.readline.chomp
        if first_line
          first_line = false
        else
          fields = line.split(/\|/, -1)
          cui_to_name[fields[2]] = fields[1]
        end
      end
    rescue EOFError
      # we're done
    end
  end
  return cui_to_name
end


file1_ingreds = read_file_data(file1)
file2_ingreds = read_file_data(file2)

# Create a map of the differences, from the name to the cui and file,
# so we can sort the differences by name.
name_to_cui = {}
file1_ingreds.keys.each do |cui|
  name_to_cui[file1_ingreds[cui]] = [cui, file1] if !file2_ingreds[cui]
end
file2_ingreds.keys.each do |cui|
  name_to_cui[file2_ingreds[cui]] = [cui, file2] if !file1_ingreds[cui]
end

name_to_cui.keys.sort {|a,b| a.downcase<=>b.downcase}.each do |name|
  cui, file = name_to_cui[name]
  if file == file1
    a = 'x'
    b = ''
  else
    a = ''
    b = 'x'
  end

  puts "#{a}\t#{b}\t#{cui}\t#{name}"
end
