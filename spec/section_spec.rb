# frozen_string_literal: true

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"
require "speech"
require "person"
require "name"
require "count"
require "builder_alpha_attributes"

describe Section do
  let!(:person) { Person.new(name: Name.new(first: "John", last: "Smith"), count: 1) }
  let!(:member) { Period.new(person: person, house: House.representatives, count: 1) }

  describe "#to_time" do
    describe "with time set" do
      subject do
        Section.new(time: "9:14", url: "url", count: Count.new(3, 1), date: Date.new(2006, 1, 1),
                    house: House.representatives)
      end

      it "should combine the date and time attributes to return a Time object" do
        expect(subject.to_time).to be_eql(Time.local(2006, 1, 1, 9, 14))
      end
    end
  end
end
