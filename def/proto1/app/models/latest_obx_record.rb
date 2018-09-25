class LatestObxRecord < ActiveRecord::Base
  belongs_to :first_test, :class_name => "ObxObservation", :foreign_key => :first_obx_id
  belongs_to :last_test, :class_name => "ObxObservation", :foreign_key => :last_obx_id

  # Go through all user data and get the latest OBX records and update the
  # latest_obx_records table
  # Parameters:
  # * profile_id a profile's id , optional
  def self.update_latest_obx_records(profile_id=nil)
    start = Time.now
    LatestObxRecord.transaction do
      # update all profiles data
      if profile_id.blank?
        # clean up the table first
        LatestObxRecord.delete_all
        profiles = Profile.all
        # deal with each profile
        profiles.each do |profile|
          loinc_nums = ObxObservation.where("profile_id=? and latest=? and obx5_value is not null", profile.id, true).
              select(:loinc_num).distinct
          loinc_nums.each do |loinc_num|
            # first
            first_obx_rec = ObxObservation.where("profile_id=? and latest=? and loinc_num=?", profile.id, true, loinc_num.loinc_num).
                order('test_date_ET ASC').first
            # last
            last_obx_rec  = ObxObservation.where("profile_id=? and latest=? and loinc_num=?", profile.id, true, loinc_num.loinc_num).
                order('test_date_ET DESC').first
            LatestObxRecord.create!(
                :profile_id => profile.id,
                :loinc_num => loinc_num.loinc_num,
                :first_obx_id => first_obx_rec.id,
                :last_obx_id => last_obx_rec.id
            )
          end
        end
      # update one profile's data
      else
        LatestObxRecord.delete_all(["profile_id=?", profile_id])
        loinc_nums = ObxObservation.where("profile_id=? and latest=? and obx5_value is not null", profile_id, true).
            select(:loinc_num).distinct
        loinc_nums.each do |loinc_num|
          # first
          first_obx_rec = ObxObservation.where("profile_id=? and latest=? and loinc_num=?", profile_id, true, loinc_num.loinc_num).
              order('test_date_ET ASC').first
          # last
          last_obx_rec  = ObxObservation.where("profile_id=? and latest=? and loinc_num=?", profile_id, true, loinc_num.loinc_num).
              order('test_date_ET DESC').first
          LatestObxRecord.create!(
              :profile_id => profile_id,
              :loinc_num => loinc_num.loinc_num,
              :first_obx_id => first_obx_rec.id,
              :last_obx_id => last_obx_rec.id
          )

        end
      end # end of if profile_id.blank?
    end # end of transaction
    puts "Updating latest_obx_records finished in #{Time.now - start} seconds"
  end

end
