require "../spec_helper"

describe Obelisk::Lexers::C do
  lexer = Obelisk::Lexers::C.new

  describe "#config" do
    it "has correct configuration" do
      config = lexer.config
      config.name.should eq "c"
      config.aliases.should contain "c"
      config.aliases.should contain "cpp"
      config.aliases.should contain "c++"
      config.filenames.should contain "*.c"
      config.filenames.should contain "*.cpp"
      config.filenames.should contain "*.h"
      config.filenames.should contain "*.hpp"
      config.mime_types.should contain "text/x-csrc"
      config.mime_types.should contain "text/x-c++src"
    end
  end

  describe "#tokenize" do
    it "tokenizes preprocessor directives" do
      tokens = lexer.tokenize("#include <stdio.h>\n#define MAX 100").to_a
      
      tokens[0].type.should eq Obelisk::TokenType::CommentPreproc
      tokens[0].value.should eq "#include"
      tokens[2].type.should eq Obelisk::TokenType::LiteralString
      tokens[2].value.should eq "<stdio.h>"
    end

    it "tokenizes C keywords" do
      tokens = lexer.tokenize("int main() { return 0; }").to_a
      
      tokens.select { |t| t.type == Obelisk::TokenType::KeywordType }.map(&.value).should contain "int"
      tokens.select { |t| t.type == Obelisk::TokenType::Keyword }.map(&.value).should contain "return"
    end

    it "tokenizes C++ keywords" do
      tokens = lexer.tokenize("class Foo : public Bar { virtual void method() override; }").to_a
      
      tokens.select { |t| t.type == Obelisk::TokenType::Keyword }.map(&.value).should contain "class"
      tokens.select { |t| t.type == Obelisk::TokenType::Keyword }.map(&.value).should contain "public"
      tokens.select { |t| t.type == Obelisk::TokenType::Keyword }.map(&.value).should contain "virtual"
      tokens.select { |t| t.type == Obelisk::TokenType::Keyword }.map(&.value).should contain "override"
    end

    it "tokenizes numbers in various formats" do
      code = "42 0xFF 0755 0b1010 3.14f 2.71828e-10"
      tokens = lexer.tokenize(code).to_a
      
      # Decimal
      tokens.find { |t| t.value == "42" }.not_nil!.type.should eq Obelisk::TokenType::LiteralNumberInteger
      
      # Hexadecimal
      tokens.find { |t| t.value == "0xFF" }.not_nil!.type.should eq Obelisk::TokenType::LiteralNumberHex
      
      # Octal
      tokens.find { |t| t.value == "0755" }.not_nil!.type.should eq Obelisk::TokenType::LiteralNumberOct
      
      # Binary
      tokens.find { |t| t.value == "0b1010" }.not_nil!.type.should eq Obelisk::TokenType::LiteralNumberBin
      
      # Float
      tokens.find { |t| t.value == "3.14f" }.not_nil!.type.should eq Obelisk::TokenType::LiteralNumberFloat
      tokens.find { |t| t.value == "2.71828e-10" }.not_nil!.type.should eq Obelisk::TokenType::LiteralNumberFloat
    end

    it "tokenizes string and character literals" do
      code = %q{"Hello" 'a' L"Wide" u8"UTF-8" '\n'}
      tokens = lexer.tokenize(code).to_a
      
      # Regular string
      string_tokens = tokens.select { |t| t.type.literal_string_double? }
      string_tokens.map(&.value).join.should contain "Hello"
      
      # Character literals
      tokens.select { |t| t.type == Obelisk::TokenType::LiteralStringChar }.map(&.value).should contain "'a'"
      tokens.select { |t| t.type == Obelisk::TokenType::LiteralStringChar }.map(&.value).should contain "'\\n'"
    end

    it "tokenizes comments" do
      code = <<-CODE
      // Single line comment
      /* Multi-line
         comment */
      int x = 5; // inline comment
      CODE
      
      tokens = lexer.tokenize(code).to_a
      
      single_comments = tokens.select { |t| t.type == Obelisk::TokenType::CommentSingle }
      single_comments.size.should eq 2
      single_comments.first.value.should eq "// Single line comment"
      
      multi_comments = tokens.select { |t| t.type == Obelisk::TokenType::CommentMultiline }
      multi_comments.should_not be_empty
    end

    it "tokenizes operators" do
      code = "a + b - c * d / e % f << g >> h & i | j ^ k"
      tokens = lexer.tokenize(code).to_a
      
      operators = tokens.select { |t| t.type == Obelisk::TokenType::Operator }
      operators.map(&.value).should contain "+"
      operators.map(&.value).should contain "-"
      operators.map(&.value).should contain "*"
      operators.map(&.value).should contain "/"
      operators.map(&.value).should contain "%"
      operators.map(&.value).should contain "<<"
      operators.map(&.value).should contain ">>"
      operators.map(&.value).should contain "&"
      operators.map(&.value).should contain "|"
      operators.map(&.value).should contain "^"
    end

    it "tokenizes C++ specific operators" do
      code = "obj->member Class::method ptr.*memptr obj->*memptr"
      tokens = lexer.tokenize(code).to_a
      
      operators = tokens.select { |t| t.type == Obelisk::TokenType::Operator }
      operators.map(&.value).should contain "->"
      operators.map(&.value).should contain "::"
      operators.map(&.value).should contain ".*"
      operators.map(&.value).should contain "->*"
    end

    it "identifies function calls" do
      code = "printf(\"Hello\"); std::cout << value;"
      tokens = lexer.tokenize(code).to_a
      
      functions = tokens.select { |t| t.type == Obelisk::TokenType::NameFunction }
      functions.map(&.value).should contain "printf"
    end

    it "tokenizes type names" do
      code = "int x; char* str; std::string name; FILE* fp;"
      tokens = lexer.tokenize(code).to_a
      
      types = tokens.select { |t| t.type == Obelisk::TokenType::KeywordType }
      types.map(&.value).should contain "int"
      types.map(&.value).should contain "char"
      
      classes = tokens.select { |t| t.type == Obelisk::TokenType::NameClass }
      classes.map(&.value).should contain "std::string"
      classes.map(&.value).should contain "FILE"
    end

    it "tokenizes constants" do
      code = "NULL nullptr true false MAX_SIZE PI"
      tokens = lexer.tokenize(code).to_a
      
      keyword_constants = tokens.select { |t| t.type == Obelisk::TokenType::KeywordConstant }
      keyword_constants.map(&.value).should contain "NULL"
      keyword_constants.map(&.value).should contain "nullptr"
      keyword_constants.map(&.value).should contain "true"
      keyword_constants.map(&.value).should contain "false"
      
      name_constants = tokens.select { |t| t.type == Obelisk::TokenType::NameConstant }
      name_constants.map(&.value).should contain "MAX_SIZE"
      name_constants.map(&.value).should contain "PI"
    end
  end

  describe "#analyze" do
    it "scores C code highly" do
      c_code = <<-CODE
      #include <stdio.h>
      
      int main() {
          printf("Hello, World!\\n");
          return 0;
      }
      CODE
      
      lexer.analyze(c_code).should be > 0.5
    end

    it "scores C++ code highly" do
      cpp_code = <<-CODE
      #include <iostream>
      
      namespace MyApp {
          class Widget {
          public:
              virtual void draw() const = 0;
          };
      }
      
      int main() {
          std::cout << "Hello, C++!" << std::endl;
          return 0;
      }
      CODE
      
      lexer.analyze(cpp_code).should be > 0.7
    end

    it "scores non-C/C++ code low" do
      ruby_code = <<-CODE
      def hello
        puts "Hello, Ruby!"
      end
      
      hello
      CODE
      
      lexer.analyze(ruby_code).should be < 0.3
    end
  end
end