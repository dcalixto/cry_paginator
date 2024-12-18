require "db"
require "./paginator/*"

module Paginator
  @@db : DB::Database? = nil
  @@default_config = {
    per_page:    12,
    order_by:    "created_at DESC",
    window_gap:  false,
    window_size: 2,
  }

  def self.db
    @@db || raise RuntimeError.new("Database connection not set. Call Paginator.db = your_database_connection first")
  end

  def self.db=(connection : DB::Database)
    @@db = connection
  end

  def self.config
    @@default_config
  end

  def self.config=(new_config : Hash(Symbol, _))
    @@default_config = {
      per_page:    new_config[:per_page]?.as?(Int32) || @@default_config[:per_page],
      order_by:    new_config[:order_by]?.as?(String) || @@default_config[:order_by],
      window_gap:  new_config[:window_gap]?.as?(Bool) || @@default_config[:window_gap],
      window_size: new_config[:window_size]?.as?(Int32) || @@default_config[:window_size],
    }
  end

  class Page(T)
    getter items : Array(T)
    getter total : Int64
    getter total_pages : Int32
    getter current_page : Int32
    getter per_page : Int32
    getter window_gap : Bool
    getter window_size : Int32

    def initialize(@items : Array(T), @total : Int64, @current_page : Int32, @per_page : Int32, @window_gap = false, @window_size = 2)
      @total_pages = (@total / @per_page.to_f).ceil.to_i
    end

    def next_page
      current_page < total_pages ? current_page + 1 : nil
    end

    def prev_page
      current_page > 1 ? current_page - 1 : nil
    end

    def first_page?
      current_page == 1
    end

    def last_page?
      current_page == total_pages
    end

    def pages
      return (1..total_pages).to_a unless window_gap

      window = [] of Int32 | Symbol

      if total_pages <= (window_size * 2) + 4
        return (1..total_pages).to_a
      end

      # Always include first page
      window << 1

      if current_page > window_size + 2
        window << :gap
      end

      # Calculate window around current page
      from = [current_page - window_size, 2].max
      to = [current_page + window_size, total_pages - 1].min

      (from..to).each { |page| window << page }

      if current_page < total_pages - (window_size + 1)
        window << :gap
      end

      # Always include last page
      window << total_pages unless window.includes?(total_pages)

      window
    end
  end

  macro included
    def self.paginate(db : DB::Database, page : Int32,
                      per_page : Int32 = Paginator.config[:per_page],
                      order_by : String = Paginator.config[:order_by],
                      where : String? = nil,
                      window_gap : Bool = Paginator.config[:window_gap],
                      window_size : Int32 = Paginator.config[:window_size])
      raise ArgumentError.new("Page must be >= 1") if page < 1
      offset = (page - 1) * per_page

      query = ["SELECT * FROM #{table_name}"]
      query << "WHERE #{where}" if where
      query << "ORDER BY #{order_by}"
      query << "LIMIT $1 OFFSET $2"

      items = [] of self
      db.query(query.join(" "), args: [per_page, offset]) do |rs|
        rs.each do
          items << new(rs)
        end
      end

      count_query = ["SELECT COUNT(*) FROM #{table_name}"]
      count_query << "WHERE #{where}" if where
      total = db.scalar(count_query.join(" ")).as(Int64)

      Paginator::Page(self).new(
        items: items,
        total: total,
        current_page: page,
        per_page: per_page,
        window_gap: window_gap,
        window_size: window_size
      )
    end
  end

  #  method for testing purposes
  def self.reset_db_for_testing
    @@db = nil
  end
end
