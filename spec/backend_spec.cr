require "spectator"
require "../src/cry_paginator"

# Add mock DB setup at the top
class MockDB < DB::Database
  def initialize(uri : URI)
    connection_options = DB::Connection::Options.new
    pool_options = DB::Pool::Options.new
    super(connection_options, pool_options) { build_connection }
  end

  protected def build_connection
    MockConnection.new
  end
end

# class MockConnection < DB::Connection
#   def initialize
#     super(DB::Connection::Options.new)
#   end

#   def build_prepared_statement(query) : DB::Statement
#     MockStatement.new(self)
#   end

#   def build_unprepared_statement(query) : DB::Statement
#     MockStatement.new(self)
#   end
# end
class MockConnection < DB::Connection
  def initialize
    super(DB::Connection::Options.new)
  end

  def build_prepared_statement(query) : DB::Statement
    MockStatement.new(self, query)
  end

  def build_unprepared_statement(query) : DB::Statement
    MockStatement.new(self, query)
  end
end

class MockStatement < DB::Statement
  protected def perform_query(args : Enumerable) : DB::ResultSet
    MockResultSet.new(self)
  end

  protected def perform_exec(args : Enumerable) : DB::ExecResult
    DB::ExecResult.new(0_i64, 0_i64)
  end
end

class MockResultSet < DB::ResultSet
  @column_index = 0

  def move_next : Bool
    false
  end

  def column_count : Int32
    0
  end

  def column_name(index : Int32) : String
    ""
  end

  def read
    nil
  end

  def next_column_index : Int32
    @column_index
  end
end

class TestHelper
  include Paginator::Backend

  def params
    @params ||= {} of String => String
  end

  def params=(new_params)
    @params = new_params
  end
end

Spectator.describe TestHelper do
  let(helper) { TestHelper.new }
  let(mock_params) { {"page" => "2", "per_page" => "5"} }

  # Add before_all hook to set up database
  before_all do
    uri = URI.parse("mock://localhost")
    Paginator.db = MockDB.new(uri)
  end

  before_each do
    helper.params = mock_params
  end

  describe "#paginator_get_count" do
    it "returns the count for a collection responding to count" do
      collection = [1, 2, 3, 4, 5]
      expect(helper.paginator_get_count(collection, {} of Symbol => String)).to eq(5)
    end
  end

  describe "#paginator" do
    context "when the collection supports `paginate`" do
      class MockCollection
        def paginate(db, page, per_page, order_by)
          items = [1, 2, 3, 4, 5]
          Paginator::Page(Int32).new(
            items: items,
            total: 20_i64, # Explicitly use Int64
            current_page: page,
            per_page: per_page
          )
        end
      end

      let(collection) { MockCollection.new }

      it "uses the `paginate` method of the collection" do
        page_instance, items = helper.paginator(collection)
        expect(page_instance).to be_a(Paginator::Page(Int32))
        expect(page_instance.current_page).to eq(2)
        expect(page_instance.total).to eq(20)
        expect(page_instance.per_page).to eq(5)
        expect(items).to eq([1, 2, 3, 4, 5])
      end
    end

    context "when the collection does not support `paginate`" do
      let(collection) { (1..20).to_a }

      it "falls back to manual pagination" do
        page_instance, items = helper.paginator(collection)
        expect(page_instance.current_page).to eq(2)
        expect(page_instance.total).to eq(20)
        expect(page_instance.per_page).to eq(5)
        expect(items).to eq([6, 7, 8, 9, 10])
      end
    end
  end

  describe "#paginator_get_items" do
    context "when the collection supports `offset` and `limit`" do
      class MockActiveRecordCollection
        @offset : Int32 = 0 # Add type annotation with default value

        def offset(value)
          @offset = value
          self
        end

        def limit(value)
          [@offset + 1, @offset + 2, @offset + 3]
        end
      end

      let(collection) { MockActiveRecordCollection.new }

      it "fetches paginated items using `offset` and `limit`" do
        items = helper.paginator_get_items(collection, 2, 3)
        expect(items).to eq([4, 5, 6])
      end
    end

    context "when the collection does not support `offset` and `limit`" do
      let(collection) { (1..20).to_a }

      it "manually slices the collection" do
        items = helper.paginator_get_items(collection, 2, 5)
        expect(items).to eq([6, 7, 8, 9, 10])
      end

      it "returns an empty array when out of bounds" do
        items = helper.paginator_get_items(collection, 5, 10)
        expect(items).to eq([] of Int32)
      end
    end
  end

  after_all do
    Paginator.db.try(&.close)
  end
end
