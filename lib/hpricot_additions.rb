require 'rubygems'
require 'hpricot'

module Hpricot
  module Traverse
    # Iterate over the children that aren't text nodes
    def each_child_node
      children.each do |c|
        yield c if c.respond_to?(:name)
      end
    end
  end
end
