class RxnormToMplusDrug < ActiveRecord::Base

  MPLUS_DRUG_PREFIX = 'http://www.nlm.nih.gov/medlineplus/druginfo/meds/';
  MPLUS_DRUG_SUFFIX = '.html';

  def mplus_drug_url()
    MPLUS_DRUG_PREFIX + urlid + MPLUS_DRUG_SUFFIX
  end

end
