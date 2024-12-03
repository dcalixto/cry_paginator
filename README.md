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
  paginator:
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

## Testing

Use spectator to write tests:

# spec/paginator_spec.cr

require "spec"
require "../src/paginator"

```crystal
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
