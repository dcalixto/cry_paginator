module Paginator
  module Backend
    private def paginator(collection, **options)
      count = paginator_get_count(collection, options)
      limit = paginator_get_limit(options)
      page = paginator_get_page(options)

      page_instance = Paginator::Page(typeof(collection.first)).new(
        items: paginator_get_items(collection, page, limit),
        total: count.to_i64,
        current_page: page,
        per_page: limit
      )

      {page_instance, page_instance.items}
    end

    private def paginator_get_count(collection, options = {} of Symbol => String)
      if collection.responds_to?(:count)
        collection.is_a?(Array) ? collection.size : collection.count
      else
        collection.size
      end
    end

    private def paginator_get_items(collection, page, limit)
      offset = (page - 1) * limit

      if collection.responds_to?(:offset) && collection.responds_to?(:limit)
        collection.offset(offset).limit(limit)
      else
        collection[offset, limit]? || [] of typeof(collection.first)
      end
    end

    private def paginator_get_limit(options)
      (options[:per_page]? || Paginator.config[:per_page]).to_i
    end

    private def paginator_get_page(options)
      page_param = options[:page_param]? || :page
      (params[page_param.to_s]? || "1").to_i
    end
  end
end
