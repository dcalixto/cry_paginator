module Paginator::ViewHelper
  PAGE_TOKEN = "__page__"

  # Generate a link with the given page and text
  def pagination_link(page : Int32 | Nil, text : String, current: false, disabled: false, extra_classes = "")
    classes = [] of String
    classes << "pagination-link"
    classes << "current" if current
    classes << "disabled" if disabled
    classes.concat(extra_classes.split)

    href = page.nil? || disabled ? "#" : "?page=#{page}"

    <<-HTML
    <a href="#{href}" class="#{classes.join(" ")}" #{"aria-current='page'" if current}>
      #{text}
    </a>
    HTML
  end

  # Generate navigation links for pagination
  def pagination_nav(paginator : Paginator::Page, base_url : String = "/", extra_classes = "")
    nav_classes = ["pagination-nav", extra_classes].join(" ")

    <<-HTML
    <nav class="#{nav_classes}" aria-label="Pagination">
      #{pagination_prev(paginator)}
      #{pagination_window(paginator)}
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

  # Generate the window of pagination links
  def pagination_window(paginator : Paginator::Page)
    paginator.page_window.map do |page|
      if page.is_a?(Int32)
        pagination_link(page, page.to_s, current: page == paginator.current_page)
      elsif page == :gap
        <<-HTML
        <span class="pagination-gap">…</span>
        HTML
      else
        raise "Unexpected pagination window value: #{page.inspect}"
      end
    end.join("\n")
  end

  # Display pagination info (e.g., "Showing items 1-10 of 100")
  def pagination_info(paginator : Paginator::Page, item_name : String = "items")
    <<-HTML
    <div class="pagination-info">
      Showing #{paginator.current_page * paginator.per_page - paginator.per_page + 1}-#{[paginator.current_page * paginator.per_page, paginator.total].min}
      of #{paginator.total} #{item_name}.
    </div>
    HTML
  end
end
