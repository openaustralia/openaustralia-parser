require "hpricot"

module Hpricot
  module Traverse
    # Iterate over the children that aren't text nodes
    def each_child_node(&block)
      child_nodes.each(&block)
    end

    def child_nodes
      containers
    end

    def map_child_node(&block)
      child_nodes.map(&block)
    end

    def append(str)
      self.inner_html = inner_html + str
    end
  end
end
