class ClassCacheVersion < ActiveRecord::Base
  MAX_VERSION = 88888888 # prevent version number from exceding Integer's limit

  def self.latest_version(model, form)
    raise "In order to get latest version number, "+
      "please provide model and form information" if form.nil?
    rec = self.find_or_create_by(
      class_name: model.name.underscore, form_name: form.form_name)
    rec.update_attributes(:version => 0) unless rec.version
    rec.version
  end

  def self.update(model, form)
    if form
      rec = self.find_or_create_by(
        class_name: model.name.underscore, form_name: form.form_name)
      v = rec.version ? rec.version + 1 : 0
      v = 0 if v > MAX_VERSION
      rec.update_attributes(:version => v)
    else
      false
    end
  end
  
end

