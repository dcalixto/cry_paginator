require "./spec_helper"

describe Paginator do
  describe "Page" do
    it "paginates data correctly" do
      data = (1..50).to_a
      page = Paginator::Page(Int32).new(
        items: data[0...10],
        total: 50_i64,
        current_page: 1,
        per_page: 10
      )

      page.total_pages.should eq(5)
      page.items.size.should eq(10)
      page.first_page?.should be_true
      page.last_page?.should be_false
    end

    it "calculates next and previous pages" do
      data = (1..50).to_a
      page = Paginator::Page(Int32).new(
        items: data[10...20],
        total: 50_i64,
        current_page: 2,
        per_page: 10
      )

      page.next_page.should eq(3)
      page.prev_page.should eq(1)
    end
  end
end
