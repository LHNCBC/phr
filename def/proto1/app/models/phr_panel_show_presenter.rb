# A Presenter class for the show action of PhrPanelsController.
class PhrPanelShowPresenter
  attr_reader :test_info # arrays of [display level, row data]

  # Creates a presenter.
  #
  # Parameters:
  # * obr - the OBR record being displayed
  def initialize(obr)
    @obr = obr
    # Until we have repeating sections, assume that loinc_num values
    # are unique within a top-level panel.
    loinc_to_obx = {}
    @obr.obx_observations.each {|obx| loinc_to_obx[obx.loinc_num] = obx}
    @test_info = []
    headings = []
    PanelData.get_panel_timeline_def(@obr.loinc_num).each do |pd|
      # The panel title level 1, so skip that.  Also skip the panel_info
      # fields (e.g. comment).
      start_level = 2
      display_level = pd['disp_level']  # (the indent level)
      if display_level >= start_level and !pd['panel_info']
        if pd['is_test']
          obx = loinc_to_obx[pd['loinc_num']]
          if obx
            headings.each_with_index {|h, i| @test_info << [i, h] if h}
            headings = []
            @test_info << [display_level, obx]
          end
        else
          headings[display_level] = pd['name']
          # Remove any headings at levels beyond display_level.  (They no
          # longer apply.)
          if display_level+1 < headings.length
            headings.slice!((display_level+1)..-1)
          end
        end
      end
    end
  end
end
