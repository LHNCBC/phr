class TextListItem < ActiveRecord::Base
  has_paper_trail
  belongs_to :text_list
  has_many :text_list_items, :foreign_key => :parent_item_id,
    :dependent => :destroy
  belongs_to :parent_item, :class_name=>'TextListItem',
    :foreign_key=> :parent_item_id

  extend HasSearchableLists
  include HasClassification

  validates_presence_of :code
  # Set up the index.  We include :text_list_id so that we can distinguish
  # between the lists during a search.
  set_up_searchable_list(:item_name, [:text_list_id, :item_name, :item_text])

  DEFAULT_CODE_COLUMN="code"

  validate :validate_instance
  def validate_instance
    # Moved from "def save", which was breaking Rails when a
    # TextListItem was added to a TextList.
    self.code = TextListItem.maximum(:id).to_i + 1 if self.code.nil?
    self.sequence_num = TextListItem.maximum(:id).to_i + 1 if self.sequence_num.nil?
  end

  # Returns the symbol for the list ID column.
  def self.get_list_id_column
    :text_list_id
  end


  # Gives back the id for a text list based on the name
  def self.get_list_id_from_name(name)
    TextList.find_by_list_name(name).id
  end


  # Returns the heading for this list item, or nil if there isn't one.
  def heading
    TextListItem.find_by_id_and_text_list_id(self.parent_item_id,
      self.text_list_id)
  end


  # Returns a map from the given list item codes to the codes of their
  # heading items (if they have headings).  If the given list items do not
  # have codes, nil is returned.  This is used by the autocompleter code
  # to distinguish items from headings.
  #
  # Parameters:
  # * list_items - the items for which a map to heading codes is needed.
  def self.map_to_heading_code(list_items)
    heading_map = {}
    list_items.each do |li|
      c = li.code
      h = li.heading
      if h
        heading_map[c] = h.code
      end
    end
    heading_map = nil if heading_map.size==0
    return heading_map
  end


  # Returns a sublist associated with this list item.  The returned structure
  # is a array of two elements, the first of which is the array of item texts,
  # and the second of which is the corresponding array of item codes.
  # Parematers:
  # * conditions -  (optional) a condition, a list of conditions, or a hashmap
  #   of conditions to be added to the normal matching statement for rows
  #   to be included in the results from the list named by the name parameter.
  def get_sublist(cond=nil)
    list_items = []
    codes = []

    get_sublist_items(cond).each do |i|
      list_items << i.item_text
      codes << i.code
    end

    return [list_items, codes]
  end


   #
   # return a list of sub item record objects
   #
   # Parameters:
   # * cond - optional query conditions, could be a hashmap, string
   #          or an array of strings
   #
   # Returns:
   # * list_items - an array of record objects
   #
   def get_sublist_items(cond=nil)
    item_recs = TextListItem.where(parent_item_id: id).order(:sequence_num)
    if cond
      case cond
      when Array
        cond.each {|c| items_recs = item_recs.where(c)}
      when String, Hash
        item_recs = item_recs.where(cond)
      end
    end

    return items_recs.load
  end


  # Returns all the childrens of current record
  def children
    TextListItem.where(parent_item_id: self.id).all
  end

  # Returns all descendants of current record
  def descendants
    children.empty? ? [] : children.map{|e| e.descendants }.flatten
  end



end
