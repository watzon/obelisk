require "../spec_helper"

describe Obelisk::Lexers::SQL do
  lexer = Obelisk::Lexers::SQL.new

  describe "#config" do
    it "has correct name and aliases" do
      config = lexer.config
      config.name.should eq("sql")
      config.aliases.should contain("mysql")
      config.aliases.should contain("postgresql")
      config.aliases.should contain("postgres")
      config.aliases.should contain("sqlite")
      config.aliases.should contain("mssql")
      config.aliases.should contain("tsql")
      config.aliases.should contain("plsql")
      config.aliases.should contain("oracle")
    end

    it "has correct filenames" do
      config = lexer.config
      config.filenames.should contain("*.sql")
      config.filenames.should contain("*.ddl")
      config.filenames.should contain("*.dml")
    end
  end

  describe "#tokenize" do
    it "tokenizes SQL keywords" do
      code = "SELECT * FROM users WHERE active = true"
      tokens = lexer.tokenize(code).to_a
      
      tokens.select { |t| t.type == Obelisk::TokenType::KeywordReserved }.map(&.value).should contain("SELECT")
      tokens.select { |t| t.type == Obelisk::TokenType::Keyword }.map(&.value).should contain("FROM")
      tokens.select { |t| t.type == Obelisk::TokenType::Keyword }.map(&.value).should contain("WHERE")
    end

    it "tokenizes SQL functions" do
      code = "SELECT COUNT(*), SUM(amount), AVG(price) FROM orders"
      tokens = lexer.tokenize(code).to_a
      
      tokens.select { |t| t.type == Obelisk::TokenType::NameBuiltin }.map(&.value).should contain("COUNT")
      tokens.select { |t| t.type == Obelisk::TokenType::NameBuiltin }.map(&.value).should contain("SUM")
      tokens.select { |t| t.type == Obelisk::TokenType::NameBuiltin }.map(&.value).should contain("AVG")
    end

    it "tokenizes data types" do
      code = "CREATE TABLE test (id INT, name VARCHAR(255), created_at TIMESTAMP)"
      tokens = lexer.tokenize(code).to_a
      
      tokens.select { |t| t.type == Obelisk::TokenType::KeywordType }.map(&.value).should contain("INT")
      tokens.select { |t| t.type == Obelisk::TokenType::KeywordType }.map(&.value).should contain("VARCHAR")
      tokens.select { |t| t.type == Obelisk::TokenType::KeywordType }.map(&.value).should contain("TIMESTAMP")
    end

    it "tokenizes string literals" do
      code = "SELECT * FROM users WHERE name = 'John O''Brien'"
      tokens = lexer.tokenize(code).to_a
      
      string_tokens = tokens.select { |t| t.type == Obelisk::TokenType::LiteralStringSingle }
      string_tokens.map(&.value).join.should eq("'John O''Brien'")
    end

    it "tokenizes comments" do
      code = <<-SQL
      -- Single line comment
      SELECT /* inline comment */ id
      FROM users
      /* Multi-line
         comment */
      SQL
      
      tokens = lexer.tokenize(code).to_a
      
      single_comments = tokens.select { |t| t.type == Obelisk::TokenType::CommentSingle }
      single_comments.size.should eq(1)
      single_comments.first.value.should eq("-- Single line comment")
      
      multi_comments = tokens.select { |t| t.type == Obelisk::TokenType::CommentMultiline }
      multi_comments.size.should be > 0
    end

    it "tokenizes identifiers with quotes" do
      code = %q{SELECT "user name", `column`, [field] FROM table}
      tokens = lexer.tokenize(code).to_a
      
      name_tokens = tokens.select { |t| t.type == Obelisk::TokenType::NameOther }
      name_tokens.map(&.value).should contain("user name")
      name_tokens.map(&.value).should contain("column")
      name_tokens.map(&.value).should contain("field")
    end

    it "tokenizes numbers" do
      code = "SELECT 123, 45.67, 1.23e4 FROM numbers"
      tokens = lexer.tokenize(code).to_a
      
      int_tokens = tokens.select { |t| t.type == Obelisk::TokenType::LiteralNumberInteger }
      int_tokens.map(&.value).should contain("123")
      
      float_tokens = tokens.select { |t| t.type == Obelisk::TokenType::LiteralNumberFloat }
      float_tokens.map(&.value).should contain("45.67")
      float_tokens.map(&.value).should contain("1.23e4")
    end

    it "tokenizes operators" do
      code = "WHERE a = b AND c <> d OR e BETWEEN 1 AND 10"
      tokens = lexer.tokenize(code).to_a
      
      operators = tokens.select { |t| t.type == Obelisk::TokenType::Operator }.map(&.value)
      operators.should contain("=")
      operators.should contain("<>")
      
      word_operators = tokens.select { |t| t.type == Obelisk::TokenType::OperatorWord }.map(&.value)
      word_operators.should contain("AND")
      word_operators.should contain("OR")
    end

    it "tokenizes bind parameters" do
      code = "SELECT * FROM users WHERE id = ? AND name = :name AND email = @email AND age > $1"
      tokens = lexer.tokenize(code).to_a
      
      params = tokens.select { |t| t.type == Obelisk::TokenType::NameVariable }.map(&.value)
      params.should contain("?")
      params.should contain(":name")
      params.should contain("@email")
      params.should contain("$1")
    end

    it "handles case-insensitive keywords" do
      code = "select * FROM Users WHERE Active = TRUE"
      tokens = lexer.tokenize(code).to_a
      
      # Keywords should be recognized regardless of case
      tokens.any? { |t| t.value == "select" && t.type == Obelisk::TokenType::KeywordReserved }.should be_true
      tokens.any? { |t| t.value == "FROM" && t.type == Obelisk::TokenType::Keyword }.should be_true
      tokens.any? { |t| t.value == "WHERE" && t.type == Obelisk::TokenType::Keyword }.should be_true
      tokens.any? { |t| t.value == "TRUE" && t.type == Obelisk::TokenType::KeywordConstant }.should be_true
    end
  end

  describe "#analyze" do
    it "gives high score to SQL code" do
      code = <<-SQL
      SELECT u.id, u.name, COUNT(o.id) as order_count
      FROM users u
      LEFT JOIN orders o ON u.id = o.user_id
      WHERE u.created_at >= '2024-01-01'
      GROUP BY u.id, u.name
      HAVING COUNT(o.id) > 5
      ORDER BY order_count DESC
      SQL
      
      lexer.analyze(code).should be >= 0.8
    end

    it "gives low score to non-SQL code" do
      code = <<-JS
      function hello() {
        console.log("Hello, world!");
        return true;
      }
      JS
      
      lexer.analyze(code).should be < 0.3
    end

    it "recognizes various SQL dialects" do
      mysql_code = "SELECT * FROM users LIMIT 10"
      lexer.analyze(mysql_code).should be > 0.5
      
      postgres_code = "SELECT * FROM users WHERE data @> '{\"active\": true}'::jsonb"
      lexer.analyze(postgres_code).should be > 0.5
      
      mssql_code = "SELECT TOP 10 * FROM users"
      lexer.analyze(mssql_code).should be > 0.5
    end
  end
end