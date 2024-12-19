require "db"
require "./paginator/*"

module Paginator
  VERSION = "0.1.0"

  # Core defaults that can be customized
  DEFAULT = {
    count_args: [:all],
    ends:       true,
    limit:      20,
    outset:     0,
    page:       1,
    page_param: :page,
    size:       7,
    overflow:   :empty_page,
  }

  module SharedMethods
    private def assign_vars(default, vars)
      @vars = default.merge(vars.reject { |k, v| default.has_key?(k) && (v.nil? || v.empty?) })
    end

    private def assign_and_check(name_min)
      name_min.each do |name, min|
        value = @vars[name]
        raise ArgumentError.new("#{name} must be >= #{min}") unless value.responds_to?(:to_i) && value.to_i >= min
        instance_variable_set("@#{name}", value.to_i)
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
      @last = @vars[:max_pages].to_i if @vars[:max_pages]? && @last > @vars[:max_pages]
    end
  end

  class Page(T)
    include SharedMethods

    getter items : Array(T)
    getter count : Int64
    getter from : Int32
    getter to : Int32
    getter last : Int32
    getter next : Int32?
    getter prev : Int32?
    getter offset : Int32
    getter vars : Hash(Symbol, Int32 | String | Symbol | Bool)

    def initialize(@items : Array(T), **vars)
      assign_vars(DEFAULT, vars)
      assign_and_check({count: 0, page: 1, outset: 0})
      assign_limit
      assign_offset
      assign_last
      check_overflow

      @from = [@offset - @outset + 1, @count].min
      @to = [@offset - @outset + @limit, @count].min
      assign_prev_and_next
    end

    def series(size = @vars[:size])
      return [] of Int32 | Symbol if size.zero?

      series = [] of Int32 | Symbol
      if size >= @last
        series.concat((1..@last).to_a)
      else
        left = ((size - 1) / 2.0).floor
        start = if @page <= left
                  1
                elsif @page > (@last - size + left)
                  @last - size + 1
                else
                  @page - left
                end

        (start...(start + size)).each { |p| series << p }

        if @vars[:ends] && size >= 7
          series[0] = 1
          series[1] = :gap unless series[1] == 2
          series[-2] = :gap unless series[-2] == @last - 1
          series[-1] = @last
        end
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
