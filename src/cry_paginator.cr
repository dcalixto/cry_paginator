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
      @last = @vars[:max_pages].to_i if @vars[:max_pages]? && @last > @vars[:max_pages]
    end
  end

  class Page(T)
    include SharedMethods

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
