# frozen_string_literal: true

require_relative "../spec_helper"
require "date_with_future"

RSpec.describe DateWithFuture do
  it "handles a normal date" do
    expect(DateWithFuture.new(2000, 1, 2).to_s).to eq "2000-01-02"
  end

  it "returns the future sentinel date" do
    expect(DateWithFuture.future).to eq DateWithFuture.new(9999, 12, 31)
  end
end
