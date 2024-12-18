require "../spec_helper"
require "spectator"

class ViewHelperTest
  include Paginator::ViewHelper
end

Spectator.describe ViewHelperTest do
  subject(paginator) do
    Paginator::Page(String).new(
      items: ["item1", "item2"],
      total: 50_i64,
      current_page: 3,
      per_page: 10
    )
  end

  describe "#pagination_nav" do
    it "generates the full pagination navigation bar" do
      html = ViewHelperTest.new.pagination_nav(subject)
      expect(html).to contain("pagination-nav")
      expect(html).to contain("Previous")
      expect(html).to contain("Next")
    end
  end
end
