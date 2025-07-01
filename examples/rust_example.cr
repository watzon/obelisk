require "../src/obelisk"

# Example Rust code to highlight
rust_code = <<-RUST
use std::collections::HashMap;

// A trait for printable items
trait Printable {
    fn format(&self) -> String;
}

/// A simple struct with lifetimes
#[derive(Debug, Clone)]
struct Person<'a> {
    name: &'a str,
    age: u32,
}

impl<'a> Person<'a> {
    fn new(name: &'a str, age: u32) -> Self {
        Person { name, age }
    }
    
    fn greet(&self) {
        println!("Hello, my name is {} and I'm {} years old!", self.name, self.age);
    }
}

impl<'a> Printable for Person<'a> {
    fn format(&self) -> String {
        format!("{} ({})", self.name, self.age)
    }
}

// A generic function with constraints
fn process_items<T: Clone + std::fmt::Debug>(items: Vec<T>) -> Vec<T> 
where 
    T: PartialEq,
{
    items.into_iter()
        .filter(|item| {
            println!("Processing {:?}", item);
            true
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_person_creation() {
        let person = Person::new("Alice", 30);
        assert_eq!(person.name, "Alice");
        assert_eq!(person.age, 30);
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Constants and variables
    const MAX_SIZE: usize = 100;
    let mut count = 0u32;
    let name = "Bob";
    
    // Create a person
    let person = Person::new(name, 25);
    person.greet();
    
    // Use a macro
    vec![1, 2, 3].iter().for_each(|&x| {
        println!("Number: {}", x);
    });
    
    // Pattern matching
    let result = match count {
        0 => "zero",
        1..=10 => "small",
        11..=50 => "medium",
        _ => "large",
    };
    
    // Error handling
    let file_content = std::fs::read_to_string("config.toml")?;
    
    // Raw string
    let regex = r#"\\d{3}-\\d{3}-\\d{4}"#;
    
    // Byte string
    let bytes = b"Hello, world!";
    
    // Different number formats
    let hex = 0xFF_FF;
    let binary = 0b1010_1010;
    let octal = 0o755;
    let float = 3.14f64;
    
    // Character and byte literals
    let ch = '\\n';
    let byte = b'A';
    
    Ok(())
}

// Async example
async fn fetch_data(url: &str) -> Result<String, reqwest::Error> {
    let response = reqwest::get(url).await?;
    response.text().await
}

// Unsafe code
unsafe fn dangerous_operation(ptr: *const u8) {
    let value = *ptr;
    println!("Value: {}", value);
}
RUST

# Test with different formatters
puts "=== Terminal Formatter (Monokai) ==="
puts Obelisk.highlight(rust_code, "rust", "terminal", "monokai")

puts "\n=== HTML Formatter (GitHub) ==="
html = Obelisk.highlight(rust_code, "rust", "html", "github")
puts html[0..500] + "... (truncated)"

puts "\n=== Plain Text Formatter ==="
plain = Obelisk.highlight(rust_code, "rust", "plain")
puts plain[0..200] + "... (truncated)"

# Test lexer detection
lexer = Obelisk.lexer("rust")
if lexer
  puts "\n=== Lexer Info ==="
  puts "Name: #{lexer.config.name}"
  puts "Aliases: #{lexer.config.aliases.join(", ")}"
  puts "Filenames: #{lexer.config.filenames.join(", ")}"
  puts "MIME types: #{lexer.config.mime_types.join(", ")}"

  # Test analyze method
  score = lexer.analyze(rust_code)
  puts "Confidence score: #{score}"
end
