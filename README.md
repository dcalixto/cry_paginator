# cry_paginator

A simple, flexible, and high-performance pagination library for Crystal inspired by Ruby's Pagy gem.

## Features

- Lightweight and fast
- Configurable pagination options
- Support for SQL queries with `crystal-db`
- Dynamic pagination window with gaps
- Methods for checking first/last page and navigating between pages
- Type-safe Crystal implementation

## Installation

Add the shard to your `shard.yml`:

```yaml
dependencies:
  cry_paginator:
    github: dcalixto/cry_paginator
```

Then, run shards install.

## Usage

- Include Paginator in Your Model

- To enable pagination on a model, include the Paginator module in your model class:

```crystal
require "paginator"

class Article
  include Paginator

  # Mock table name for demonstration
  def self.table_name
    "articles"
  end
end
```

## Paginate Your Data

Use the paginate method to fetch paginated records:

```crystal
# Database setup
DB = DB.open("sqlite3://db.sqlite3")

# Paginate articles
page = Article.paginate(page: 1, per_page: 10)

puts page.items         # Array of fetched articles
puts page.total         # Total number of articles
puts page.current_page  # Current page
puts page.total_pages   # Total number of pages

# Navigation
puts page.next_page     # Next page number or nil
puts page.prev_page     # Previous page number or nil

# Custom Page Window
puts page.page_window(7) # Example output: [1, :gap, 5, 6, 7, 8, :gap, 20]

```

## Configuration

Override the defaults globally in your app:

```crystal
Paginator.config = {
  per_page: 20,
  order_by: "created_at DESC"
}
```

Or override them for individual calls:

```crystal
Page.paginate(page: 2, per_page: 20, order_by: "created_at DESC")
```

## Dynamic Pagination Window

Display a pagination window with gaps for easy navigation:

```crystal
puts page.page_window # Example output: [1, :gap, 8, 9, 10, :gap, 36]
```

## Controller Setup

The controller retrieves paginated data from the database using the Paginator shard.

_Example: ArticlesController (Kemal Framework)_

```crystal
require "./models/article" # Assuming Article includes Paginator

class ArticlesController
  def self.index(env)
    page = env.params.query["page"]? || 1
    per_page = 10

    articles_page = Article.paginate(page.to_i, per_page: per_page)

    env.render("articles/index.ecr", {
      articles: articles_page.items,
      paginator: articles_page
    })
  end
end
```

## Integration in Views

Use the data provided by the controller to render paginated content and navigation links.

_Example Usage in a Kemal View (index.ecr)_

```crystal
<%= pagination_nav(paginator) %>
<%= pagination_info(paginator, "articles") %>
```

_Example Output_
Navigation Links

```crystal
<nav class="pagination-nav" aria-label="Pagination">
  <a href="?page=1" class="pagination-link">Previous</a>
  <a href="?page=1" class="pagination-link">1</a>
  <a href="#" class="pagination-link current" aria-current="page">2</a>
  <a href="?page=3" class="pagination-link">3</a>
  <span class="pagination-gap">…</span>
  <a href="?page=10" class="pagination-link">10</a>
  <a href="?page=3" class="pagination-link">Next</a>
</nav>
```

**Info**

```crystal
<div class="pagination-info">
  Showing 11-20 of 100 articles.
</div>
```

## Styles for Pagination

Add some simple CSS to style the pagination links.

```css
.pagination-nav {
  display: flex;
  gap: 0.5rem;
  list-style: none;
}

.pagination-link {
  padding: 0.5rem 1rem;
  background: #007bff;
  color: #fff;
  text-decoration: none;
  border-radius: 3px;
}

.pagination-link.current {
  background: #0056b3;
  font-weight: bold;
}

.pagination-link.disabled {
  background: #ddd;
  color: #aaa;
  pointer-events: none;
}

.pagination-gap {
  display: inline-block;
  padding: 0.5rem;
  color: #666;
}
```

## Testing

Use spectator to write tests:

_spec/paginator_spec.cr_

```crystal
require "spec"
require "../src/paginator"


describe Paginator do
  it "returns paginated data" do
    # Test logic here
  end
end
```

Run the tests:

```crystal
crystal spec
```

## Contributing

1. Fork it (https://github.com/dcalixto/cry_paginator/fork)
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## License

This shard is available as open source under the terms of the MIT License.
