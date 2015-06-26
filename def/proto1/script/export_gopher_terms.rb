#!/bin/env ruby
$LOAD_PATH.unshift(File.join(File.absolute_path(File.dirname($0)), '../config'))
require 'environment.rb'

all_gt_data = []
fields = %w{id key_id primary_name term_icd9_code term_icd9_text
  consumer_name included_in_phr is_procedure document_weight word_synonyms
  synonyms info_link_data}
GopherTerm.first
GopherTerm.all.each do |gt|
  gt_data = {}
  fields.each {|k| gt_data[k] = gt.send(k)}
  all_gt_data.push(gt_data)
end

puts all_gt_data.to_json
