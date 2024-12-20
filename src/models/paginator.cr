module Paginator
  class Page(T)
    getter current_page : Int32
    getter per_page : Int32
    getter items : Array(T)
    getter count : Int64
  end
end
