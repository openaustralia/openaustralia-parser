# frozen_string_literal: true

require_relative "../spec_helper"
require "hansard_speech"

RSpec.describe HansardSpeech do
  describe ".generic_speaker?" do
    %w[
      Honourable\ member
      Honourable\ members
      Government\ member
      Government\ members
      Opposition\ member
      Opposition\ members
      a\ government\ member
    ].each do |name|
      it "recognises '#{name}' as a generic speaker" do
        expect(HansardSpeech.generic_speaker?(name)).to be_truthy
      end
    end

    it "does not treat a real name as a generic speaker" do
      expect(HansardSpeech.generic_speaker?("John Smith")).to be_falsy
    end
  end
end
