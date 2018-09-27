class UpdateCaptchaInstr < ActiveRecord::Migration[5.1]
  def self.up
    if MIGRATE_FFAR_TABLES
      FieldDescription.transaction do
        instr_v2 = 'Help us keep spammers out and keep your account safe. <p>If you have trouble reading the displayed pictures, click on the circular arrows for another set of pictures, or select an audio challenge by clicking the <img  src="https://www.gstatic.com/recaptcha/api2/audio_black.png" alt="captcha audio challenge speaker" width="15" height="15"> icon. <a href="javascript:void(0)" onclick="return Def.Popups.openHelp(this, \'/help/audio_captcha_tips.shtml\')">Tips for using the CAPTCHA audio challenge.</a></p>'
        FieldDescription.where(target_field: 'captcha_instr', form_id: [37,40,45]).update_all(default_value: instr_v2)
      end
    end
  end

  def self.down
    if MIGRATE_FFAR_TABLES
      FieldDescription.transaction do
        instr_v1 = "Help us keep spammers out and keep your account safe. <p>If you have trouble reading the displayed words or numbers, click on the circular arrows for another set of words or numbers, or select an audio challenge by clicking the <img  src=\"/help/red_speaker__small_icon.png \" alt=\"captcha audio challenge speaker\" width=\"15\" height=\"15\"> icon. <a href=\"javascript:void(0)\" onclick=\"return Def.Popups.openHelp(this, '/help/audio_captcha_tips.shtml')\">Tips for using the CAPTCHA audio challenge.</a></p>"
        FieldDescription.where(target_field: 'captcha_instr', form_id: [37,40,45]).update_all(default_value: instr_v1)
      end
    end
  end
end
