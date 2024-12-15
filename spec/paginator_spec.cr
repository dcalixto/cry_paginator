require "spec"
require "spectator"
require "db"
require "sqlite3"
require "../src/cry_paginator"
require "./support/item"

# Define Item class at the top level
class Item
  property id : Int32?
  property name : String?

  def initialize(@id = nil, @name = nil)
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int32?)
    @name = rs.read(String?)
  end

  def self.table_name
    "items"
  end
end

include Paginator
Spectator.describe Paginator do
  describe "Paginator.db" do
    context "when no database connection is set" do
      it "raises an error" do
        expect { Paginator.db }.to raise_error(RuntimeError, "Database connection not set. Call Paginator.db = your_database_connection first")
      end
    end

    context "when a database connection is set" do
      let(:mock_db) { DB.open "sqlite3::memory:" }

      before_each do
        Paginator.db = mock_db
      end

      it "returns the set database connection" do
        expect(Paginator.db).to eq(mock_db)
      end
    end
  end

  describe Paginator::Page do
    let(:page) { Paginator::Page(String).new(["item1", "item2"], 50, 2, 10) }

    it "generates a page window with gaps" do
      page = Paginator::Page(Int32).new([1, 2, 3], 50, 3, 10)
      expect(page.page_window(5)).to eq([1, :gap, 2, 3, 4, :gap, 5])
    end

    it "returns next_page correctly" do
      expect(page.next_page).to eq(3)
    end

    it "returns nil for next_page on the last page" do
      page = Paginator::Page(String).new(["item1"], 10, 5, 2)
      expect(page.next_page).to be_nil
    end

    it "returns prev_page correctly" do
      expect(page.prev_page).to eq(1)
    end

    it "returns nil for prev_page on the first page" do
      page = Paginator::Page(String).new(["item1"], 10, 1, 2)
      expect(page.prev_page).to be_nil
    end

    it "identifies first_page? correctly" do
      page = Paginator::Page(String).new(["item1"], 10, 1, 2)
      expect(page.first_page?).to be_truthy
    end

    it "identifies last_page? correctly" do
      page = Paginator::Page(String).new(["item1"], 10, 5, 2)
      expect(page.last_page?).to be_truthy
    end

    it "generates a page window with gaps" do
      # Test case 1: window size 5
      expect(page.page_window(5)).to eq([1, :gap, 2, 3, 4, :gap, 5])

      # Test case 2: window size 3
      expect(page.page_window(3)).to eq([1, :gap, 2, 3, 4, :gap, 5])
    end

    it "generates a full page window without gaps when total pages <= size" do
      page = Paginator::Page(String).new(["item1"], 5, 2, 2)
      expect(page.page_window(5)).to eq([1, 2, 3])
    end
  end

  describe "Paginator.paginate macro" do
    let(:mock_db) { DB.open "sqlite3::memory:" }

    before_each do
      Paginator.db = mock_db
      mock_db.exec "DROP TABLE IF EXISTS items"
      mock_db.exec <<-SQL
        CREATE TABLE items (
          id INTEGER PRIMARY KEY,
          name TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      SQL
      mock_db.exec "INSERT INTO items (name) VALUES (?)", "item1"
      mock_db.exec "INSERT INTO items (name) VALUES (?)", "item2"
    end

    it "paginates query results" do
      result = Item.paginate(Paginator.db, 1, 1)
      expect(result.items.first.try(&.name)).to eq("item1")
      expect(result.total).to eq(2)
      expect(result.current_page).to eq(1)
    end

    it "throws an error for invalid page numbers" do
      expect { Item.paginate(Paginator.db, 0) }.to raise_error(ArgumentError, "Page must be >= 1")
    end
  end
end
