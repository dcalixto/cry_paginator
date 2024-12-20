require "db"
require "./paginator/*"

module Paginator
  VERSION = "0.1.0"

  # Define DEFAULT as a Hash directly
  DEFAULT = Hash(Symbol, Array(Symbol) | Bool | Int32 | String | Symbol).new.merge({
    :count_args => [:all],
    :ends       => true,
    :limit      => 20,
    :outset     => 0,
    :page       => 1,
    :page_param => :page,
    :size       => 7,
    :overflow   => :empty_page,
  })

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

        # Use direct assignment instead of instance_variable_set
        case name
        when :page
          @page = value.to_i
        when :outset
          @outset = value.to_i
        when :limit
          @limit = value.to_i
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

      # Convert max_pages to Int32 before comparison
      if max_pages = @vars[:max_pages]?
        max_pages_int = max_pages.is_a?(Number) ? max_pages.to_i : nil
        @last = max_pages_int if max_pages_int && @last > max_pages_int
      end
    end
  end

  class Page(T)
    # Define all getters
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

    def initialize(@items : Array(T), @count : Int64, **vars)
      # Initialize all required instance variables
      @current_page = vars[:page]?.try(&.to_i) || 1
      @page = @current_page
      @per_page = vars[:limit]?.try(&.to_i) || DEFAULT[:limit].as(Int32)
      @limit = @per_page
      @outset = vars[:outset]?.try(&.to_i) || DEFAULT[:outset].as(Int32)
      @offset = (@limit * (@page - 1)) + @outset
      @last = [(@count.to_f / @limit).ceil, 1].max.to_i
      @vars = DEFAULT.dup
      @prev = @page > 1 ? @page - 1 : nil
      @next = @page == @last ? nil : @page + 1

      assign_vars(DEFAULT, vars)
      assign_limit
      assign_offset
      assign_last
      check_overflow
    end

    def prev_page : Int32?
      return nil if current_page <= 1
      current_page - 1
    end

    def next_page : Int32?
      return nil if current_page >= total_pages
      current_page + 1
    end

    def total_pages : Int32
      (@count.to_f / per_page).ceil.to_i
    end

    def series
      return [] of Int32 if total_pages < 1

      window_size = @vars[:size].as(Int32)

      if total_pages <= window_size
        (1..total_pages).to_a
      else
        series = [] of Int32 | Symbol

        # Always show first page
        series << 1

        # Calculate window around current page
        half_window = (window_size - 2) // 2
        window_start = [@page - half_window, 2].max
        window_end = [@page + half_window, total_pages - 1].min

        # Add gap after 1 if needed
        series << :gap if window_start > 2

        # Add window pages
        (window_start..window_end).each { |p| series << p }

        # Add gap before last page if needed
        series << :gap if window_end < total_pages - 1

        # Always show last page
        series << total_pages

        series
      end
    end

    private def assign_prev_and_next
      @prev = @page > 1 ? @page - 1 : nil
      @next = @page == @last ? nil : @page + 1
    end

    private def check_overflow
      raise OverflowError.new("Page #{@page} exceeds last page (#{@last})") if @page > @last
    end
  end

  class OverflowError < Exception; end
end
