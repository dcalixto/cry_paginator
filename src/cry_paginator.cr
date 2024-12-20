require "db"
require "./paginator/*"

module Paginator
  VERSION = "0.1.0"

  # First, define the DEFAULT hash correctly
  DEFAULT = Hash(Symbol, Array(Symbol) | Bool | Int32 | String | Symbol).new
  DEFAULT[:count_args] = [:all]
  DEFAULT[:ends] = true
  DEFAULT[:limit] = 20
  DEFAULT[:outset] = 0
  DEFAULT[:page] = 1
  DEFAULT[:page_param] = :page
  DEFAULT[:size] = 7
  DEFAULT[:overflow] = :empty_page

  # In the Post.paginate method:
  def self.paginate(page : Int32 = 1, per_page : Int32 = 12, order : String = "created_at DESC")
    offset = (page - 1) * per_page
    items = db.query_all(
      "SELECT * FROM posts ORDER BY #{order} LIMIT ? OFFSET ?",
      args: [per_page, offset],
      as: Post
    )
    count = db.scalar("SELECT COUNT(*) FROM posts").as(Int64)

    # Create vars hash with correct type
    vars = Hash(Symbol, Array(Symbol) | Bool | Int32 | String | Symbol).new
    vars[:page] = page
    vars[:limit] = per_page
    vars[:order_by] = order

    Paginator::Page(Post).new(
      items: items,
      count: count,
      vars: vars
    )
  end

  module SharedMethods
    private def assign_vars(default, vars)
      vars_hash = vars.to_h
      @vars = default.merge(vars_hash.reject { |k, v| default.has_key?(k) && v.nil? })
    end

    private def assign_and_check(name_min)
      name_min.each_key do |name|
        value = @vars[name]
        min = name_min[name]
        raise ArgumentError.new("#{name} must be >= #{min}") unless value.responds_to?(:to_i) && value.to_i >= min

        # Type-safe assignment using case statement
        case name
        when :page   then @page = value.to_i
        when :outset then @outset = value.to_i
        when :limit  then @limit = value.to_i
        end
      end
    end

    private def assign_limit
      assign_and_check({limit: 1})
    end

    private def assign_offset
      @offset = (@limit * (@page - 1)) + @outset
    end

    private def assign_last
      @last = [(@count.to_f / @limit).ceil, 1].max.to_i

      # Safe type conversion for max_pages
      if max_pages = @vars[:max_pages]?
        max_pages_int = max_pages.is_a?(Number) ? max_pages.to_i : nil
        @last = max_pages_int if max_pages_int && @last > max_pages_int
      end
    end
  end

  class Page(T)
    include SharedMethods

    # Define getters with explicit types
    getter per_page : Int32
    getter current_page : Int32
    getter items : Array(T)
    getter count : Int64
    getter last : Int32
    getter offset : Int32
    getter vars : Hash(Symbol, Array(Symbol) | Int32 | String | Symbol | Bool)
    getter prev : Int32?
    getter next : Int32?
    getter page : Int32
    getter limit : Int32
    getter outset : Int32

    def initialize(@items : Array(T), @count : Int64, vars : Hash(Symbol, _))
      @vars = DEFAULT.dup.merge(vars)
      @current_page = @vars[:page].as(Int32)
      @page = @current_page
      @per_page = @vars[:limit].as(Int32)
      @limit = @per_page

      # Handle outset with explicit type checking
      @outset = case value = @vars[:outset]?
                when String then value.to_i
                when Int32  then value
                when Nil    then DEFAULT[:outset].as(Int32)
                else             DEFAULT[:outset].as(Int32)
                end

      @offset = (@limit * (@page - 1)) + @outset
      @last = [(@count.to_f / @limit).ceil, 1].max.to_i
      @prev = @page > 1 ? @page - 1 : nil
      @next = @page == @last ? nil : @page + 1
    end

    def prev_page : Int32?
      return nil if @page <= 1
      @page - 1
    end

    def next_page : Int32?
      return nil if @page >= @last
      @page + 1
    end
  end

  class OverflowError < Exception; end
end
