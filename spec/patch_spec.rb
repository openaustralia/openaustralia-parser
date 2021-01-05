$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"

require 'patch'

describe Patch do
  before :each do
    @original = <<~EOF
      Mary had a little lamb
      whose fleece was white as snow.
      And everywhere that Mary went
      the lamb was sure to go.
    EOF

    @patch = <<~EOF
      --- a	2009-04-02 13:46:31.000000000 +1100
      +++ b	2009-04-02 13:48:02.000000000 +1100
      @@ -1,4 +1,3 @@
       Mary had a little lamb
       whose fleece was white as snow.
      -And everywhere that Mary went
      -the lamb was sure to go.
      +And everywhere that Mary went the lamb was sure to go.
    EOF
  end

  it "can patch a string with a unified diff and return a new string" do
    expect(Patch::patch(@original, @patch)).to eq <<~EOF
      Mary had a little lamb
      whose fleece was white as snow.
      And everywhere that Mary went the lamb was sure to go.
    EOF
  end

  it "raises an error when the patch doesn't go" do
    expect { Patch.patch("foo", @patch) }.to raise_error(RuntimeError)
  end
end
