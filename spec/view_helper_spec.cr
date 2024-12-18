require "./spec_helper"
require "../src/cry_paginator"

class ViewHelperTest
  include Paginator::ViewHelper
  extend Paginator::ViewHelper
end

describe ViewHelperTest do
  describe "#pagination_nav" do
    it "generates the full pagination navigation bar" do
      paginator = Paginator::Page(String).new(
        items: ["item1", "item2"],
        total: 50_i64,
        current_page: 3,
        per_page: 10
      )

      html = ViewHelperTest.pagination_nav(paginator)
      html.should contain("pagination-nav")
      html.should contain("Previous")
      html.should contain("Next")
    end
  end
end
