require "spectator"
require "../src/cry_paginator"
require "./spec_helper"

Spectator.describe Paginator::ViewHelper do
  include Paginator::ViewHelper

  let paginator do
    Paginator::Page(String).new(["item1", "item2"], 50, 3, 10)
  end

  describe "#pagination_link" do
    it "generates a basic link for a given page" do
      html = pagination_link(2, "2")
      expect(html).to eq(%(<a href="?page=2" class="pagination-link">2</a>))
    end

    it "generates a link with 'is-current' class for the current page" do
      html = pagination_link(3, "3", current: true)
      expect(html).to eq(%(<a href="?page=3" class="pagination-link is-current">3</a>))
    end

    it "generates a link with 'is-disabled' class for disabled links" do
      html = pagination_link(nil, "Previous", disabled: true)
      expect(html).to eq(%(<a href="#end" class="pagination-link is-disabled">Previous</a>))
    end

    it "adds extra CSS classes if provided" do
      html = pagination_link(2, "2", extra_classes: "custom-class")
      expect(html).to eq(%(<a href="?page=2" class="pagination-link custom-class">2</a>))
    end
  end

  describe "#pagination_nav" do
    it "generates the full pagination navigation bar" do
      html = pagination_nav(paginator)
      expect(html).to contain("pagination-nav")
      expect(html).to contain("Previous")
      expect(html).to contain("Next")
    end
  end

  describe "#pagination_prev" do
    it "generates a link to the previous page when available" do
      html = pagination_prev(paginator)
      expect(html).to eq(%(<a href="?page=2" class="pagination-link">Previous</a>))
    end

    it "generates a disabled link when no previous page exists" do
      paginator = Paginator::Page(String).new(["item1"], 10, 1, 2)
      html = pagination_prev(paginator)
      expect(html).to eq(%(<a href="#end" class="pagination-link is-disabled">Previous</a>))
    end
  end

  describe "#pagination_next" do
    it "generates a link to the next page when available" do
      html = pagination_next(paginator)
      expect(html).to eq(%(<a href="?page=4" class="pagination-link">Next</a>))
    end

    it "generates a disabled link when no next page exists" do
      paginator = Paginator::Page(String).new(["item1"], 10, 5, 2)
      html = pagination_next(paginator)
      expect(html).to eq(%(<a href="#end" class="pagination-link is-disabled">Next</a>))
    end
  end

  describe "#pagination_window" do
    it "generates pagination links for a page window" do
      html = pagination_window(paginator)
      expect(html).to contain(%(<a href="?page=2" class="pagination-link">2</a>))
      expect(html).to contain(%(<a href="?page=3" class="pagination-link is-current">3</a>))
    end

    it "includes a gap symbol for skipped pages" do
      items = [] of Item
      page = Paginator::Page(Item).new(items, 100_i64, 6, 10)
      html = pagination_window(page)

      expect(html).to contain("<span class=\"pagination-gap\">…</span>")
    end
  end

  describe "#pagination_info" do
    it "displays correct pagination info" do
      items = [] of Item
      page = Paginator::Page(Item).new(items, 100_i64, 2, 10)
      info = pagination_info(page)

      expect(info).to contain("Showing 11-20 of 100 items")
    end
  end
end
