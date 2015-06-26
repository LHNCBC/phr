#!/proj/def/bin/ruby
# This script sorts the lines of a file that has a header row, preserving the header row's position.
# The file is sorts should be specified as an argument on the command line.  The sorted version
# is written to STDOUT.
file = ARGV[0]
File.open(file) do |f|
  lines = f.readlines
  header = lines.shift
  print header
  print lines.sort.join
end
