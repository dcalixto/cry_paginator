# cry_paginator

A simple, flexible, and high-performance pagination library for Crystal inspired by Ruby's Pagy gem.

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
# src/models/post.cr
require "cry_paginator"
class Post
  include Paginator

  def self.table_name
    "posts"
  end

  property id : Int32
  property title : String
  property content : String
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
  window_gap: true,
  window_size: 2
  order_by: "created_at DESC"
}
```

Or override them for individual calls:

```crystal
Page.paginate(page: 2, per_page: 20, order_by: "created_at DESC")
```

## Dynamic Pagination Window

You can now use the pagination with or without window gaps:

```crystal
# Without window gap (default)
posts = Post.paginate(db, page: 1)

# With window gap
posts = Post.paginate(db, page: 1, window_gap: true)

# With custom window size
posts = Post.paginate(db, page: 1, window_gap: true, window_size: 3)

```

## Controller Setup

The controller retrieves paginated data from the database using the Paginator shard.

_Example: ArticlesController (Kemal Framework)_

```crystal
# src/controllers/posts_controller.cr
class PostsController < Kemal::Handler
  include Paginator::Backend
  include Paginator::ViewHelper

  def call(context)
    page = context.params.query["page"]? || "1"
    per_page = context.params.query["per_page"]? || "10"

    posts_query = Post.all # Your query builder
    page_instance, items = paginator(posts_query,
      page_param: :page,
      per_page: per_page.to_i,
      order_by: "created_at DESC"
    )

    render "src/views/posts/index.ecr", context
  end
end

```

## Integration in Views

Use the data provided by the controller to render paginated content and navigation links.

_Example Usage in a Kemal View (index.ecr)_

```crystal
<div class="posts">
  <% items.each do |post| %>
    <article>
      <h2><%= post.title %></h2>
      <p><%= post.content %></p>
    </article>
  <% end %>
</div>

<%= nav(page_instance, nav_aria_label: "Posts navigation") %>
<%= info(page_instance, item_name: "posts") %>

```

_Example Output_
Navigation Links

```crystal
# <nav class="pagination-nav" aria-label="Pagination">
#   <a href="?page=1" class="pagination-link">Previous</a>
#   <a href="?page=1" class="pagination-link">1</a>
#   <a href="?page=2" class="pagination-link current" aria-current="page">2</a>
#   <a href="?page=3" class="pagination-link">3</a>
#   <a href="?page=4" class="pagination-link">4</a>
#   <a href="?page=5" class="pagination-link">5</a>
#   <a href="?page=7" class="pagination-link">Next</a>
# </nav>
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
/* public/css/pagination.css */
.pagination-nav {
  display: flex;
  gap: 0.5rem;
  list-style: none;
  margin: 2rem 0;
}

.pagination-list {
  display: flex;
  gap: 0.5rem;
  list-style: none;
  margin: 0;
  padding: 0;
}

.pagination-link {
  padding: 0.5rem 1rem;

  text-decoration: none;
}

.pagination-link.is-current {
  font-weight: bold;
}

.pagination-ellipsis {
  padding: 0.5rem;
}

.pagination-previous,
.pagination-next {
  padding: 0.5rem 1rem;

  text-decoration: none;
}

.pagination-previous[disabled],
.pagination-next[disabled] {
  cursor: not-allowed;
}

.pagination-info {
  display: block;
  margin-top: 1rem;
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
