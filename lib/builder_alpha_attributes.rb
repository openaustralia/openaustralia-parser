# frozen_string_literal: true

# XML Builder with a patch to sort the attributes so that they are in alphabetical order.
# This makes it easier to do simple diffs between XML files

require "builder"

module Builder
  class XmlMarkup < XmlBase
    # Insert the attributes (given in the hash).
    def _insert_attributes(attrs, order = [])
      return if attrs.nil?

      order.each do |k|
        v = attrs[k]
        @target << %( #{k}="#{_attr_value(v)}") if v # " WART
      end
      sorted_attrs = attrs.sort { |a, b| a.first.to_s <=> b.first.to_s }
      sorted_attrs.each do |k, v|
        @target << %( #{k}="#{_attr_value(v)}") unless order.member?(k) # " WART
      end
    end
  end
end
