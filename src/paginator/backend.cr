module Paginator
  module Backend
    def paginator_get_count(collection, options = {} of Symbol => String)
      if collection.responds_to?(:count)
        # Handle Array's count method which requires a block or argument
        collection.is_a?(Array) ? collection.size : collection.count
      else
        collection.size
      end
    end

    def paginator(collection, options = {} of Symbol => String)
      page = (params["page"]? || "1").to_i
      per_page = (params["per_page"]? || Paginator.config[:per_page].to_s).to_i

      if collection.responds_to?(:paginate)
        page_instance = collection.paginate(Paginator.db, page, per_page, options[:order_by]? || Paginator.config[:order_by])
        items = page_instance.items
      else
        total = paginator_get_count(collection, options)
        items = paginator_get_items(collection, page, per_page)
        page_instance = Paginator::Page(typeof(items.first)).new(
          items: items,
          total: total.to_i64,
          current_page: page,
          per_page: per_page
        )
      end

      {page_instance, items}
    end

    def paginator_get_items(collection, page, per_page)
      offset = (page - 1) * per_page

      if collection.responds_to?(:offset) && collection.responds_to?(:limit)
        collection.offset(offset).limit(per_page)
      else
        collection[offset, per_page]? || [] of typeof(collection.first)
      end
    end
  end
end
