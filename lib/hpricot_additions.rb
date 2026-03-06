# frozen_string_literal: true

require "nokogiri"

# Extend Nokogiri::XML::Node to provide hpricot compatibility methods
module Nokogiri
  module XML
    class Node
      # Iterate over the children that aren't text nodes
      def each_child_node(&block)
        child_nodes.each(&block)
      end

      def child_nodes
        element_children
      end

      def map_child_node(&block)
        child_nodes.map(&block)
      end

      def append(str)
        self.inner_html = inner_html + str
      end

      # Traverse all text nodes and yield them
      def traverse_text(&block)
        # Iterate through all child nodes
        children.each do |child|
          if child.is_a?(Nokogiri::XML::Text)
            # Yield the text node
            yield child
          elsif child.respond_to?(:traverse_text)
            # Recursively traverse child elements
            child.traverse_text(&block)
          end
        end
      end
    end

    class NodeSet
      # Support iteration like Hpricot::Elements
      def each_child_node(&block)
        each(&block)
      end

      def child_nodes
        to_a
      end

      def map_child_node(&block)
        map(&block)
      end

      def append(str)
        each { |node| node.append(str) }
      end

      # Traverse all text nodes in all elements
      def traverse_text(&block)
        each { |node| node.traverse_text(&block) if node.respond_to?(:traverse_text) }
      end
    end
  end
end
