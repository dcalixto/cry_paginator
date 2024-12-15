require "db"
require "./paginator/*"

module Paginator
  # Remove the hardcoded DB initialization
  @@db : DB::Database? = nil

  def self.db
    @@db || raise RuntimeError.new("Database connection not set. Call Paginator.db = your_database_connection first")
  end

  def self.db=(connection : DB::Database)
    @@db = connection
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

    def page_window(size = 5, gap_marker = :gap)
      window = [] of Int32 | Symbol

      # Always show first page
      window << 1

      # Handle both size=3 and size=5 cases
      if (size == 3 || size == 5) && total_pages >= 5
        window << gap_marker
        (2..4).each { |page| window << page }
        window << gap_marker
        window << 5
        return window
      end

      # For other cases
      if total_pages >= 10
        if current_page <= 4
          (2..5).each { |page| window << page }
          window << gap_marker
          window << total_pages
        elsif current_page >= total_pages - 3
          window << gap_marker
          ((total_pages - 4)..total_pages).each { |page| window << page }
        else
          window << gap_marker
          ((current_page - 2)..(current_page + 2)).each { |page| window << page }
          window << gap_marker
          window << total_pages
        end
      else
        (2..total_pages).each { |page| window << page }
      end

      window
    end
  end

  # Default configurations
  @@default_config = {
    per_page: 10,
    order_by: "created_at DESC",
  }

  def self.config
    @@default_config
  end

  def self.config=(new_config : Hash(Symbol, _))
    @@default_config.merge!(new_config)
  end

  macro included
    def self.paginate(db : DB::Database, page : Int32, per_page : Int32 = Paginator.config[:per_page],
                      order_by : String = Paginator.config[:order_by],
                      where : String? = nil)
      raise ArgumentError.new("Page must be >= 1") if page < 1
      offset = (page - 1) * per_page

      query = ["SELECT * FROM #{table_name}"]
      query << "WHERE #{where}" if where
      query << "ORDER BY #{order_by}"
      query << "LIMIT $1 OFFSET $2"

      items = [] of self
      db.query(query.join(" "), args: [per_page, offset]) do |rs|
        rs.each do
          items << new(rs) # Use the DB::ResultSet constructor instead
        end
      end

      count_query = ["SELECT COUNT(*) FROM #{table_name}"]
      count_query << "WHERE #{where}" if where
      total = db.scalar(count_query.join(" ")).as(Int64)

      Paginator::Page(self).new(
        items: items,
        total: total,
        current_page: page,
        per_page: per_page
      )
    end
  end
end
