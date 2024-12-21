module Paginator
  module ViewHelper
    # Constants for template tokens
    PAGE_TOKEN  = "__page__"
    LABEL_TOKEN = "__page_label__"

    def pagination_info(paginator : Paginator::Page, item_name : String)
      # Calculate from and to values
      per_page = paginator.per_page
      current_page = paginator.page
      from = (current_page - 1) * per_page + 1
      to = [from + per_page - 1, paginator.count].min

      html = String.build do |html|
        if paginator.count == 0
          html << "No #{item_name}"
        else
          html << "Showing #{from}-#{to} of #{paginator.count} #{item_name}"
        end
      end
      html
    end

    def pagination_nav(page : Paginator::Page,
                       id : String? = nil,
                       nav_aria_label : String = "Pages",
                       **vars)
      link = build_link_proc(page, **vars)

      String.build do |html|
        # Nav container
        html << %(<nav#{id ? " id=\"#{id}\"" : ""} class="pagination-nav" aria-label="#{nav_aria_label}">)

        # Previous link
        build_prev_link(html, page, link)

        # Pages list
        html << %(<ul class="pagination-list">)
        build_page_links(html, page, link)
        html << "</ul>"

        # Next link
        build_next_link(html, page, link)

        html << "</nav>"
      end
    end

    private def build_link_proc(page, **vars)
      base_url = "#{request_path}?page=#{PAGE_TOKEN}"
      left, right = base_url.split(PAGE_TOKEN, 2)

      ->(p : Int32 | Symbol, text : String, classes : String | Nil, aria : Hash(Symbol, String)?) {
        nav_link(p, text, left, right, classes, aria)
      }
    end

    def pagination_link(page : Int32?, text : String, current : Bool = false, disabled : Bool = false)
      classes = ["pagination-link"]
      classes << "current" if current
      classes << "disabled" if disabled

      if page && !disabled
        "<a href=\"?page=#{page}\" class=\"#{classes.join(" ")}\">#{text}</a>"
      else
        "<span class=\"#{classes.join(" ")}\">#{text}</span>"
      end
    end

    private def nav_link(p, text : String, left : String, right : String, classes : String? = nil, aria : Hash(Symbol, String)? = nil)
      class_attr = classes ? %( class="#{classes}") : ""
      aria_attr = build_aria_attributes(aria)

      if p.is_a?(Symbol)
        %(<span#{class_attr}#{aria_attr}>#{text}</span>)
      else
        %(<a href="#{left}#{p}#{right}"#{class_attr}#{aria_attr}>#{text}</a>)
      end
    end

    private def build_link_proc(page, **vars)
      base_url = "#{request_path}?page=#{PAGE_TOKEN}"
      left, right = base_url.split(PAGE_TOKEN, 2)

      ->(p : Int32 | Symbol, text : String, classes : String | Nil, aria : Hash(Symbol, String) | Nil) do
        nav_link(p, text, left, right, classes, aria)
      end
    end

    private def build_page_links(html, page, link)
      puts "Pagination Debug:"

      # puts "Current page: #{page.page}"
      puts "Current page: #{page.current_page}"
      puts "Total items: #{page.count}"
      puts "Items per page: #{page.per_page}"
      puts "Total pages: #{page.total_pages}"
      puts "Page series: #{page.series.inspect}"

      page.series.each do |p|
        html << "<li>"
        case p
        when Int32
          classes = p == page.current_page ? "pagination-link is-current" : "pagination-link"
          aria = p == page.current_page ? {:current => "page"} : nil
          html << link.call(p, p.to_s, classes, aria)
        when :gap
          html << link.call(:gap, "...", "pagination-ellipsis", {:disabled => "true"})
        end
        html << "</li>"
      end
    end

    private def build_prev_link(html, page, link)
      if prev_page = page.prev_page
        html << link.call(prev_page, "Previous", "pagination-previous", nil)
      else
        html << %(<span class="pagination-previous" disabled>Previous</span>)
      end
    end

    private def build_next_link(html, page, link)
      if next_page = page.next_page
        html << link.call(next_page, "Next", "pagination-next", nil)
      else
        html << %(<span class="pagination-next" disabled>Next</span>)
      end
    end

    private def build_aria_attributes(aria : Hash(Symbol, String)?) : String
      return "" unless aria
      aria.map { |k, v| %( aria-#{k}="#{v}") }.join
    end

    # Placeholder for i18n integration
    private def t(key : String, **vars) : String
      # Implement your i18n logic here
      case key
      when "pagy.info.empty"
        "No #{vars[:item_name]}"
      when "pagy.info.single_page"
        "Displaying #{vars[:count]} #{vars[:item_name]}"
      when "pagy.info.multiple_pages"
        "Showing #{vars[:from]}-#{vars[:to]} of #{vars[:count]} #{vars[:item_name]}"
      else
        key
      end
    end

    private def request_path
      # Implement based on your web framework
      "/"
    end
  end
end
