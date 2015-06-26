require 'test_helper'

class TextListTest < ActiveSupport::TestCase
  fixtures :text_lists, :text_list_items

  # Tests the get_list_items method
  def test_get_list_items
    # Try getting a list by name
    list = TextList.get_list_items('Dose')
    assert_equal(1, list.size, 'dose list size')
    assert_equal('3 Tbsp', list[0].item_text)

    # Try getting a list using an order
    list = TextList.get_list_items('Route', nil,
      ['item_name', 'item_text'], nil)
    assert_equal(3, list.size, 'order')
    assert_equal('PO', list[2].item_name)

    # Try getting a list using a condition
    list = TextList.get_list_items('Route', nil, nil, 'id=-24935')
    assert_equal(1, list.size, 'condition')
    assert_equal('By Mouth', list[0].item_text)
  end


  # Tests csv_dump, defined in active_record_extensions.rb
  def test_csv_dump
    all_items = TextListItem.csv_dump
    lines = all_items.split("\n")
    assert(lines.length > 4)
    test_list = text_lists(:route)
    list_13 = TextListItem.csv_dump(:text_list_id=>test_list.id)
    lines = list_13.split("\n")
    assert_equal(5, lines.length) # 3 plus 2 header rows

    # Check that the values are in the correct order for the columns.
    test_item = text_list_items(:route1)
    one_item = TextListItem.csv_dump(:code=>test_item.code)
    lines = one_item.split("\n")
    table_name_fields = lines[0].split(/,/)
    assert_equal('text_list_items', table_name_fields[1])
    col_headers = lines[1].split(/,/)
    col_vals = lines[2].split(/,/)
    expected = {'id'=>test_item.id.to_s,
      'text_list_id'=>test_item.text_list_id.to_s,
      'item_name'=>test_item.item_name, 'item_text'=>test_item.item_text,
      'item_help'=>'', 'code'=>test_item.code, 'parent_item_id'=>'',
      'info_link'=>'', 'sequence_num'=>test_item.sequence_num.to_s}
    col_headers.each_with_index do |ch, i|
      if ch != 'created_at' && ch != 'updated_at'
        assert_equal(expected[ch], col_vals[i], 'For attribute '+ch)
      end
    end

    # Also check that if an accessor method is overridden, we still get the
    # data value that is in the table.  (Example: GopherTerm's consumer_name.)
    eval <<-ENDREDEF
      class ::TextListItem
        def item_help
          return 'zzzHowdy'
        end
      end
    ENDREDEF
    all_items = TextListItem.csv_dump(:text_list_id=>test_list.id)
    assert_nil(all_items.index('zzzHowdy'))
  end

  #  Tests update_by_csv, defined in active_record_extensions.rb
  def test_update_by_csv
    # Try modifiying a TextListItem.
    tli = text_list_items(:route2)
    assert_equal('G-tube', tli.item_name)
    csv_str = "id,item_name\n#{tli.id},  Gee "
    data_edit_ori_size = DataEdit.count
    TextListItem.update_by_csv(csv_str, 1)
    tli = TextListItem.find_by_id(tli.id)
    assert_equal('Gee', tli.item_name) # trimmed of whitespace

    # Also confirm that we created a DataEdit record.
    des = DataEdit.all
    assert_equal(1, des.size - data_edit_ori_size)

    # Confirm that the backup file exists.
    backup = des[0].backup_file
    assert(File.exists?(backup))
    assert(File.size(backup))

    # Try creating a new TextListItem
    num_TLIs = TextListItem.count
    csv_str = "id,code,item_name\n,10,New Item"
    TextListItem.update_by_csv(csv_str, 1)
    assert_equal(num_TLIs+1, TextListItem.count)

    # Try deleting the new TextListItem
    new_id = TextListItem.maximum(:id)
    csv_str = "id,item_name\ndelete #{new_id}"
    TextListItem.update_by_csv(csv_str, 1)
    assert_equal(num_TLIs, TextListItem.count)
    assert_nil(TextListItem.find_by_id(new_id))
  end


  def test_build_order_options
    def TextList.build_order_options_t(ord)
      self.build_order_options(ord)
    end

    order_string = nil
    actual = TextList.build_order_options(order_string)
    expected ="sequence_num"
    assert_equal  expected, actual


    order_string = "field_a"
    actual = TextList.build_order_options(order_string)
    expected ="field_a, sequence_num"
    assert_equal  expected, actual

    order_string = ["field_a", "field_b"]
    actual = TextList.build_order_options(order_string)
    expected ="field_a, field_b, sequence_num"
    assert_equal  expected, actual
  end
end
