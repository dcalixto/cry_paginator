# cry_paginator

A simple, flexible, and high-performance pagination library for Crystal inspired by Ruby's Pagy gem.

[![Build Status](http://localhost:8080/buildStatus/icon?job=cry_paginator)](http://localhost:8080/job/cry_paginator/)
[![Crystal Test](https://github.com/dcalixto/cry_paginator/actions/workflows/crystal-test.yml/badge.svg?branch=master)](https://github.com/dcalixto/cry_paginator/actions/workflows/crystal-test.yml)

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
require "cry_paginator"

class Article
  include Paginator
  # Define your database connection
  @@db : DB::Database = DB.open("your_database_url")

# Add a class method to access the database
  def self.db
    @@db
  end
end
```

## Paginate Your Data

Use the paginate method to fetch paginated records:

```crystal
# Access pagination data
paginator.items          # Current page items
paginator.total          # Total number of items
paginator.total_pages    # Total number of pages
paginator.current_page   # Current page number
paginator.next_page      # Next page number or nil
paginator.prev_page      # Previous page number or nil

# Custom Page Window
paginator.page_window(7) # Example output: [1, :gap, 5, 6, 7, 8, :gap, 20]

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
    include Paginator::ViewHelper

    @@db : DB::Database = Article.db # Add the database type annotation on Application.cr or in the controller
    @articles : Array(Article)?
    @paginator : Paginator::Page(Article)

  def initialize
    @paginator = Article.paginate(Article.db, 1, 10)
  end

  def index(env)
     page = env.params.query["page"]?.try(&.to_i) || 1
     per_page = env.params.query["per_page"]?.try(&.to_i) || 10
     paginator = Article.paginate(Article.db, page, per_page)
     @articles = @paginator.items

     render "src/views/articles/index.ecr"
   end
end
```

## Integration in Views

Use the data provided by the controller to render paginated content and navigation links.

_Example Usage in a Kemal View (index.ecr)_

```crystal
<%= pagination_info(paginator, "articles") if paginator %>
<%= pagination_nav(paginator) if paginator %>

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
  margin-bottom: 13rem;
}

.pagination-link {
  padding: 0.5rem 1rem;

  color: #1eaedb;

  text-decoration: none;
}
.pagination-link:hover {
  text-decoration: underline;
}
.is-current {
  font-weight: bold;
}

.is-disabled {
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
