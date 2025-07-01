require "../spec_helper"

include Obelisk

describe Obelisk::Lexers::Rust do
  lexer = Obelisk::Lexers::Rust.new

  describe "#config" do
    it "has correct configuration" do
      config = lexer.config
      config.name.should eq("rust")
      config.aliases.should contain("rust")
      config.aliases.should contain("rs")
      config.filenames.should contain("*.rs")
      config.filenames.should contain("*.rs.in")
      config.mime_types.should contain("text/rust")
      config.mime_types.should contain("text/x-rust")
    end
  end

  describe "#analyze" do
    it "gives high score for Rust code" do
      rust_code = <<-RUST
      use std::io;
      
      fn main() {
          let mut name = String::new();
          println!("Enter your name:");
          io::stdin().read_line(&mut name).expect("Failed to read");
          println!("Hello, {}!", name.trim());
      }
      RUST

      score = lexer.analyze(rust_code)
      score.should be > 0.5
    end

    it "gives lower score for non-Rust code" do
      js_code = <<-JS
      function main() {
          var name = prompt("Enter your name:");
          console.log("Hello, " + name + "!");
      }
      JS

      score = lexer.analyze(js_code)
      score.should be < 0.3
    end
  end

  describe "#tokenize" do
    it "tokenizes keywords correctly" do
      code = "fn let mut const use mod pub struct enum trait impl where"
      tokens = lexer.tokenize(code).to_a

      tokens.select { |t| t.type == Obelisk::TokenType::Keyword }.size.should be >= 8
    end

    it "tokenizes types correctly" do
      code = "i32 u64 f64 bool char str String Vec Option Result"
      tokens = lexer.tokenize(code).to_a

      # Built-in types
      tokens.select { |t| t.type == TokenType::KeywordType }.size.should be >= 6
      # Built-in trait/types
      tokens.select { |t| t.type == TokenType::NameBuiltin }.size.should be >= 4
    end

    it "tokenizes macros correctly" do
      code = "println!(\"hello\") vec![1, 2, 3] format!(\"{}\", x)"
      tokens = lexer.tokenize(code).to_a

      macro_tokens = tokens.select { |t| t.type == TokenType::NameFunctionMagic }
      macro_tokens.map(&.value).should contain("println!")
      macro_tokens.map(&.value).should contain("vec!")
      macro_tokens.map(&.value).should contain("format!")
    end

    it "tokenizes lifetimes correctly" do
      code = "'a 'static '_ fn foo<'b>(x: &'b str)"
      tokens = lexer.tokenize(code).to_a

      lifetime_tokens = tokens.select { |t| t.type == TokenType::NameAttribute || t.type == TokenType::NameBuiltin }
      lifetime_tokens.map(&.value).should contain("'a")
      lifetime_tokens.map(&.value).should contain("'static")
      lifetime_tokens.map(&.value).should contain("'_")
      lifetime_tokens.map(&.value).should contain("'b")
    end

    it "tokenizes attributes correctly" do
      code = "#[derive(Debug, Clone)] #![allow(dead_code)]"
      tokens = lexer.tokenize(code).to_a

      attr_tokens = tokens.select { |t| t.type == TokenType::NameDecorator }
      attr_tokens.size.should be > 0
    end

    it "tokenizes strings correctly" do
      code = %q("hello" "world\n" r#"raw string"# b"bytes")
      tokens = lexer.tokenize(code).to_a

      string_tokens = tokens.select { |t| t.type == TokenType::LiteralStringDouble || t.type == TokenType::LiteralString }
      string_tokens.size.should be >= 4
    end

    it "tokenizes raw strings with multiple hashes" do
      code = %q(r##"this is a "raw" string"##)
      tokens = lexer.tokenize(code).to_a

      raw_string_tokens = tokens.select { |t| t.type == TokenType::LiteralString }
      raw_string_tokens.size.should be >= 2 # Opening and content
    end

    it "tokenizes numbers with suffixes correctly" do
      code = "42u32 100i64 3.14f32 0xFF_FFu16 0b1010i8 0o755"
      tokens = lexer.tokenize(code).to_a

      number_tokens = tokens.select { |t|
        [TokenType::LiteralNumberInteger, TokenType::LiteralNumberFloat,
         TokenType::LiteralNumberHex, TokenType::LiteralNumberBin,
         TokenType::LiteralNumberOct].includes?(t.type)
      }
      number_tokens.size.should eq(6)
    end

    it "tokenizes comments correctly" do
      code = <<-RUST
      // Single line comment
      /* Multi-line
         comment */
      /// Doc comment
      //! Inner doc comment
      /** Doc block */
      /*! Inner doc block */
      RUST

      tokens = lexer.tokenize(code).to_a

      single_comments = tokens.select { |t| t.type == TokenType::CommentSingle }
      multi_comments = tokens.select { |t| t.type == TokenType::CommentMultiline }
      doc_comments = tokens.select { |t| t.type == TokenType::LiteralStringDoc }

      single_comments.size.should be >= 1
      multi_comments.size.should be >= 1
      doc_comments.size.should be >= 4
    end

    it "tokenizes operators correctly" do
      code = ":: -> .. ..= + - * / % & | ^ ! ~ @ < > = ?"
      tokens = lexer.tokenize(code).to_a

      operator_tokens = tokens.select { |t| t.type == TokenType::Operator }
      operator_tokens.map(&.value).should contain("::")
      operator_tokens.map(&.value).should contain("->")
      operator_tokens.map(&.value).should contain("..")
      operator_tokens.map(&.value).should contain("..=")
    end

    it "tokenizes function definitions" do
      code = "fn hello() { } fn world<T>(x: T) -> T { x }"
      tokens = lexer.tokenize(code).to_a

      func_tokens = tokens.select { |t| t.type == TokenType::NameFunction }
      func_tokens.map(&.value).should contain("hello")
      func_tokens.map(&.value).should contain("world")
    end

    it "tokenizes format strings in macros" do
      code = %q(println!("Hello, {}!", name))
      tokens = lexer.tokenize(code).to_a

      # Should have macro name
      tokens.any? { |t| t.type == TokenType::NameFunctionMagic && t.value == "println!" }.should be_true

      # Should have interpolation
      tokens.any? { |t| t.type == TokenType::LiteralStringInterpol && t.value == "{}" }.should be_true
    end
  end
end
