require "./spec_helper"

describe Obelisk do
  it "works" do
    true.should eq(true)
  end

  it "can highlight basic text" do
    result = Obelisk.highlight("hello world", "text")
    result.should_not be_empty
  end

  it "has lexers registered" do
    Obelisk.lexer_names.should_not be_empty
    Obelisk.lexer_names.should contain("text")
  end

  it "has formatters registered" do
    Obelisk.formatter_names.should_not be_empty
    Obelisk.formatter_names.should contain("html")
  end

  it "has styles registered" do
    Obelisk.style_names.should_not be_empty
    Obelisk.style_names.should contain("github")
  end
end
