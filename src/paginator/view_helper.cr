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

    def pagination_nav(page)
      String.build do |str|
        str << "<nav class=\"pagination pagination-nav\" aria-label=\"Pagination\">"
        str << "<a href=\"?page=#{page.prev_page}\" class=\"pagination-link\">Previous</a>" if page.prev_page
        str << "<ul class=\"pagination-list\">"
        page.pages.each do |p|
          str << build_page_link(p, page.current_page)
        end
        str << "</ul>"
        str << "<a href=\"?page=#{page.next_page}\" class=\"pagination-link\">Next</a>" if page.next_page
        str << "</nav>"
      end
    end

    private def build_page_link(page_number, current_page)
      if page_number == :gap
        "<li><span class=\"pagination-gap\">…</span></li>"
      else
        current = page_number == current_page ? " is-current" : ""
        "<li><a href=\"?page=#{page_number}\" class=\"pagination-link#{current}\">#{page_number}</a></li>"
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
