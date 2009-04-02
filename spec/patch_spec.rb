$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"
require 'spec'

require 'patch'

describe Patch do
  it "can patch a string with a unified diff and return a new string" do
    original = <<EOF
Mary had a little lamb
whose fleece was white as snow.
And everywhere that Mary went
the lamb was sure to go.
EOF
    patched = <<EOF
Mary had a little lamb
whose fleece was white as snow.
And everywhere that Mary went the lamb was sure to go.
EOF

    patch = <<EOF
--- a	2009-04-02 13:46:31.000000000 +1100
+++ b	2009-04-02 13:48:02.000000000 +1100
@@ -1,4 +1,3 @@
 Mary had a little lamb
 whose fleece was white as snow.
-And everywhere that Mary went
-the lamb was sure to go.
+And everywhere that Mary went the lamb was sure to go.
EOF

    Patch::patch(original, patch).should == patched
  end
  
  #it "throws an error when the patch doesn't go"
end
