class Item
  include Paginator
  property id : Int32?
  property name : String?

  def initialize(@id = nil, @name = nil)
  end

  def self.table_name
    "items"
  end
end
