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
    def page_window(size = 5, gap_symbol = :gap)
      puts "Current page: #{current_page}"
      puts "Total pages: #{total_pages}"
      puts "Window size: #{size}"

      window = [] of Int32 | Symbol

      # For small total pages, return all pages
      return (1..total_pages).to_a if total_pages <= size

      # Always add first page
      window << 1

      # Calculate visible range around current page
      half = (size - 1) // 2
      left = current_page - half
      right = current_page + half

      # Add gap after first page if needed
      if left > 2
        window << gap_symbol
        start_page = left
      else
        start_page = 2
      end

      # Add middle pages
      (start_page..right).each do |page|
        window << page if page < total_pages
      end

      # Add gap before last page if needed
      if right < total_pages - 1
        window << gap_symbol
      end

      # Add last page if not already included
      window << total_pages unless window.last == total_pages

      puts "Window: #{window}"
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
          items << new(
            title: rs.read(String),
            body: rs.read(String),
            user_id: rs.read(Int64),
            id: rs.read(Int64?),
            slug: rs.read(String?),
            attachment: rs.read(String?),
            created_at: rs.read(Time),
            updated_at: rs.read(Time?)
          )
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
