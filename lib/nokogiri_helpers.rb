# frozen_string_literal: true

require "nokogiri"

module NokogiriHelpers
  # Return only non-text children (elements)
  # replaces Hpricot::Traverse#each_child_node monkey patch
  def self.element_children(node)
    node.children.reject(&:text?)
  end

  # Append an XML/HTML string to a node's inner content.
  # replaces Hpricot::Traverse#append monkey patch
  def self.append(node, str)
    node.inner_html = node.inner_html + str
  end
end

