require "./spec_helper"

describe Paginator do
  before_each do
    Paginator.reset_db_for_testing
  end

  it ".db raises when no database is configured" do
    expect_raises(RuntimeError, "Database connection not set. Call Paginator.db = your_database_connection first") do
      Paginator.db
    end
  end

  describe ".db" do
    it "returns the configured database connection" do
      db = DB.open "sqlite3::memory:"
      Paginator.db = db
      Paginator.db.should eq(db)
    end
  end

  describe ".config" do
    it "allows updating configuration" do
      new_config = {
        :per_page    => 20,
        :order_by    => "created_at DESC",
        :window_gap  => true,
        :window_size => 2,
      } of Symbol => Int32 | String | Bool

      Paginator.config = new_config
      Paginator.config[:per_page].should eq(20)
      Paginator.config[:window_gap].should eq(true)
    end
  end
  describe "Page" do
    it "calculates pagination details" do
      items = [1, 2, 3] of Int32
      page = Paginator::Page(Int32).new(
        items: items,
        total: 50_i64,
        current_page: 3,
        per_page: 10
      )

      page.total_pages.should eq(5)
      page.next_page.should eq(4)
      page.prev_page.should eq(2)
      page.first_page?.should be_false
      page.last_page?.should be_false
    end

    it "generates pages with window gaps" do
      items = [1, 2, 3] of Int32
      page = Paginator::Page(Int32).new(
        items: items,
        total: 100_i64,
        current_page: 5,
        per_page: 10,
        window_gap: true,
        window_size: 2
      )

      expected = [1, :gap, 3, 4, 5, 6, 7, :gap, 10]
      page.pages.should eq(expected)
    end
  end
end
