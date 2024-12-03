require "./view_helper"

module Paginator
  # Class variable for DB connection
  @@db : DB::Database? = nil

  # Add connection setter
  def self.db=(connection : DB::Database)
    @@db = connection
  end

  # Add connection getter with nil check
  def self.db
    @@db || raise "Database connection not initialized. Call Paginator.db = your_connection first"
  end

  # Holds paginated data and metadata
  class Page(T)
    getter items : Array(T)
    getter total : Int64
    getter total_pages : Int32
    getter current_page : Int32
    getter per_page : Int32

    def initialize(@items : Array(T), @total : Int64, @current_page : Int32, @per_page : Int32)
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

    # Returns a dynamic pagination window with optional gaps
    def page_window(size = 5, gap_symbol = :gap)
      half = size // 2
      start_page = [current_page - half, 1].max
      end_page = [current_page + half, total_pages].min

      if total_pages > size
        window = [1, gap_symbol] if start_page > 2
        window ||= [] of Int32 | Symbol
        window.concat((start_page..end_page).to_a)
        window.concat([gap_symbol, total_pages]) if end_page < total_pages - 1
        window
      else
        (1..total_pages).to_a
      end
    end
  end

  # Default configurations
  @@default_config = {
    per_page: 10,
    order_by: "created_at DESC",
  }

  # Dynamically inject the paginate method into any class that includes Paginator
  macro included
    # Adds a paginate method dynamically to the including class
    def self.paginate(page : Int32, per_page : Int32 = @@default_config[:per_page],
                      order_by : String = @@default_config[:order_by],
                      where : String? = nil)
      raise ArgumentError.new("Page must be >= 1") if page < 1
      offset = (page - 1) * per_page

      query = ["SELECT * FROM #{table_name}"]
      query << "WHERE #{where}" if where
      query << "ORDER BY #{order_by}"
      query << "LIMIT ? OFFSET ?"

      items = @@db.query_all(query.join(" "), args: [per_page, offset], as: self)

      count_query = ["SELECT COUNT(*) FROM #{table_name}"]
      count_query << "WHERE #{where}" if where
      total = @@db.scalar(count_query.join(" ")).as(Int64)

      Page(self).new(
        items: items,
        total: total,
        current_page: page,
        per_page: per_page
      )
    end

    # Ensure the including class defines a table_name method
    def self.table_name
      @@table_name ||= "#{self.name.split("::").last.underscore}s"
    end
  end

  # Allow global configuration of Paginator
  def self.config
    @@default_config
  end

  def self.config=(new_config : Hash(Symbol, _))
    @@default_config.merge!(new_config)
  end
end
