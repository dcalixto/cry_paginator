module Paginator
  module Backend
    # Main method to return Paginator::Page and paginated items
    def paginator(collection, page_param : String = "page", per_page_param : String = "per_page", **options)
      # Get pagination parameters
      page = (params[page_param]? || 1).to_i
      per_page = (params[per_page_param]? || Paginator.config[:per_page]).to_i

      # For database collections using cry_paginator
      if collection.responds_to?(:paginate)
        page_instance = collection.paginate(
          Paginator.db,
          page,
          per_page,
          options[:order_by]? || Paginator.config[:order_by]
        )
        items = page_instance.items
      else
        # Fallback for regular collections
        total = paginator_get_count(collection, options)
        items = paginator_get_items(collection, page, per_page)

        page_instance = Paginator::Page(typeof(items.first)).new(
          items: items,
          total: total,
          current_page: page,
          per_page: per_page
        )
      end

      [page_instance, items]
    end

    # Override to customize count logic
    def paginator_get_count(collection, options)
      collection.responds_to?(:count) ? collection.count : collection.size
    end

    # Override to customize item fetching logic
    def paginator_get_items(collection, page, per_page)
      if collection.responds_to?(:offset) && collection.responds_to?(:limit)
        collection.offset((page - 1) * per_page).limit(per_page)
      else
        collection[((page - 1) * per_page)...(page * per_page)] || [] of typeof(collection.first)
      end
    end
  end
end
