module Paginator
  module ViewHelper
    PAGE_TOKEN = "__page__"

    # Generates pagination link HTML
    def pagination_link(page : Int32 | Nil, text : String, current : Bool = false, disabled : Bool = false, extra_classes : String = "")
      classes = ["pagination-link"]
      classes << "is-current" if current
      classes << "is-disabled" if disabled
      classes << extra_classes unless extra_classes.empty?

      "<a href=\"#{page ? "?page=#{page}" : "#end"}\" class=\"#{classes.join(" ")}\">#{text}</a>"
    end

    # Generate navigation links for pagination
    def pagination_nav(paginator : Paginator::Page, base_url : String = "/", extra_classes = "", use_window : Bool = true)
      nav_classes = ["pagination", extra_classes].join(" ")

      <<-HTML
      <nav class="#{nav_classes}" aria-label="Pagination">
        #{pagination_prev(paginator)}
        
        <ul class="pagination-list">
          #{pagination_window(paginator, use_window)}
        </ul>
        
        #{pagination_next(paginator)}
      </nav>
      HTML
    end

    # Display "Previous" link
    def pagination_prev(paginator : Paginator::Page)
      if paginator.prev_page
        pagination_link(paginator.prev_page, "Previous")
      else
        pagination_link(nil, "Previous", disabled: true)
      end
    end

    # Display "Next" link
    def pagination_next(paginator : Paginator::Page)
      if paginator.next_page
        pagination_link(paginator.next_page, "Next")
      else
        pagination_link(nil, "Next", disabled: true)
      end
    end

    # Add the window pagination helper
    def window_pagination(current_page, total_pages, window_size = 10)
      # Calculate the initial window
      half_window = window_size // 2
      start_page = [1, current_page - half_window].max
      end_page = [start_page + window_size - 1, total_pages].min

      # Extend window when reaching boundaries
      if current_page + half_window > end_page && end_page < total_pages
        # Add more pages to the end
        additional_pages = [4, total_pages - end_page].min
        end_page += additional_pages
      elsif current_page - half_window < start_page && start_page > 1
        # Add more pages to the start
        additional_pages = [4, start_page - 1].min
        start_page -= additional_pages
      end

      # Adjust start_page if near the end
      # start_page = [end_page - window_size + 1, 1].max if end_page - start_page < window_size

      (start_page..end_page).to_a
    end

    # And update pagination_window to generate list items
    def pagination_window(paginator : Paginator::Page, use_window : Bool = true)
      if use_window
        window_pagination(paginator.current_page, paginator.total_pages).map do |page|
          %(<li>#{pagination_link(page, page.to_s, current: page == paginator.current_page)}</li>)
        end.join("\n")
      else
        standard_pagination_links(paginator)
      end
    end

    # Display pagination info
    def pagination_info(paginator, item_name = "items")
      start_item = ((paginator.current_page - 1) * paginator.per_page) + 1
      end_item = [start_item + paginator.per_page - 1, paginator.total].min

      <<-HTML
      <div class="pagination-info">
        Showing #{start_item}-#{end_item} of #{paginator.total} #{item_name}.
      </div>
      HTML
    end

    private def standard_pagination_links(paginator : Paginator::Page)
      (1..paginator.total_pages).map do |page|
        pagination_link(page, page.to_s, current: page == paginator.current_page)
      end.join("\n")
    end
  end
end
