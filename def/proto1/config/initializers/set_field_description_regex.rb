# Initialize the global regex variable to be used when field description has
# fields enclosed in #{}. The global variable is then accessed during sessions.
#
#require_dependency 'active_record_extensions'
#require_dependency 'active_record_cache_mgr'

start = Time.now
Rails.logger.info "\nSTART OF init user table time = "+start.to_s 
# takes less tyhan 0.25 seconds normally. uncomment logging to check

$regexMap = {}
FieldDescription.all.each do |fd|
  if !fd.default_value.blank? && fd.default_value.include?('#{')
    regex = fd.default_value.scan(/#\{[a-zA-Z0-9 \._@\!\$#\%\&\*\(\)-]*\}/)  
    if !regex.blank?
      $regexMap[fd.form_id] = []  if $regexMap[fd.form_id].blank?
      $regexMap[fd.form_id] = $regexMap[fd.form_id] + regex 
    end
  end
  
end

Rails.logger.info "\nEND OF init user table time  time = "+Time.now.to_s 
Rails.logger.info "\nEND OF init user table time total time = "+(Time.now - start).to_s 
