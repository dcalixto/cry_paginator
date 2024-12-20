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
    include SharedMethods
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

    def prev_page : Int32?
      return nil if current_page <= 1
      current_page - 1
    end

    def next_page : Int32?
      return nil if current_page >= total_pages
      current_page + 1
    end

    def total_pages : Int32
      (count / per_page.to_i64).ceil.to_i
    end

    def initialize(@items : Array(T), @current_page : Int32, @page : Int32, @per_page : Int32, @count : Int64, **vars)
      @last = 1
      @offset = 0
      @vars = DEFAULT.dup
      @prev = nil
      @next = nil
      @page = vars[:page]?.try(&.to_i) || 1
      @limit = vars[:limit]?.try(&.to_i) || DEFAULT[:limit].as(Int32)
      @outset = vars[:outset]?.try(&.to_i) || DEFAULT[:outset].as(Int32)
      assign_vars(DEFAULT, vars)
      assign_and_check({page: 1, outset: 0})
      assign_limit
      assign_offset
      assign_last
      check_overflow

      @from = [@offset - @outset + 1, @count].min
      @to = [@offset - @outset + @limit, @count].min
      assign_prev_and_next
    end

    def series(size : Int32 = @vars[:size].as(Int32))
      return [] of Int32 | Symbol if size.zero?

      series = [] of Int32 | Symbol
      total_window = size.to_i

      # Handle small page counts
      if total_window >= @last
        return (1..@last).to_a.map(&.as(Int32 | Symbol))
      end

      # Calculate the current window position
      current = @page.to_i
      half = (total_window / 2).to_i
      left_size = half
      right_size = total_window - half - 1

      # Determine start and end points
      start_page = if current <= left_size
                     1
                   elsif current > (@last - right_size)
                     @last - total_window + 1
                   else
                     current - left_size
                   end.to_i

      end_page = Math.min(start_page + total_window - 1, @last).to_i

      # Build the series
      if start_page > 1
        series << 1
        series << :gap if start_page > 2
      end

      (start_page..end_page).each do |page|
        series << page
      end

      if end_page < @last
        series << :gap if end_page < @last - 1
        series << @last
      end

      series
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
