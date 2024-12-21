module Paginator::Model
  macro included
    extend ClassMethods
  end

  module ClassMethods
    def paginate(query : DB::Query, page : Int32 = 1, per_page : Int32 = 12, order : String = "created_at DESC")
      offset = (page - 1) * per_page
      items = query.db.query_all(
        "#{query.to_s} ORDER BY #{order} LIMIT $1 OFFSET $2",
        args: [per_page, offset],
        as: self
      )
      count = query.db.scalar("SELECT COUNT(*) FROM #{table_name}").as(Int64)

      vars = Hash(Symbol, Array(Symbol) | Bool | Int32 | String | Symbol).new
      vars[:page] = page
      vars[:limit] = per_page
      vars[:order_by] = order

      Paginator::Page(self).new(
        items: items,
        count: count,
        vars: vars
      )
    end
  end
end
