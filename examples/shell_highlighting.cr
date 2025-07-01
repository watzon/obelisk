require "../src/obelisk"
require "json"

# Example Shell/Bash code to highlight
shell_code = <<-SHELL
#!/bin/bash
# This is a comment

# Variables
NAME="John Doe"
AGE=30
readonly CONSTANT="immutable"

# Special variables
echo "Script name: $0"
echo "First argument: $1"
echo "All arguments: $@"
echo "Number of arguments: $#"
echo "Process ID: $$"
echo "Exit status: $?"

# Variable expansion
echo "Hello, ${NAME}!"
echo "Age next year: $((AGE + 1))"

# Command substitution
CURRENT_DIR=$(pwd)
DATE=`date +%Y-%m-%d`

# Functions
function greet() {
    local name=$1
    echo "Hello, $name!"
}

say_goodbye() {
    echo "Goodbye, $1!"
}

# Control structures
if [ "$AGE" -ge 18 ]; then
    echo "Adult"
elif [ "$AGE" -ge 13 ]; then
    echo "Teenager"
else
    echo "Child"
fi

# Case statement
case "$NAME" in
    "John"*)
        echo "Name starts with John"
        ;;
    "Jane"*)
        echo "Name starts with Jane"
        ;;
    *)
        echo "Unknown name pattern"
        ;;
esac

# Loops
for i in {1..5}; do
    echo "Number: $i"
done

while [ $AGE -lt 40 ]; do
    AGE=$((AGE + 1))
done

# Arrays
FRUITS=("apple" "banana" "orange")
echo "First fruit: ${FRUITS[0]}"
echo "All fruits: ${FRUITS[@]}"

# String operations
STRING="Hello, World!"
echo "Length: ${#STRING}"
echo "Substring: ${STRING:7:5}"
echo "Replace: ${STRING//World/Universe}"

# Here document
cat <<EOF
This is a heredoc
Multiple lines
With variables: $NAME
EOF

# Pipelines and redirections
ls -la | grep ".sh$" > shell_files.txt 2>&1
echo "Error message" >&2

# Background jobs
sleep 10 &
SLEEP_PID=$!
wait $SLEEP_PID

# Test expressions
[[ "$NAME" =~ ^John ]] && echo "Name matches pattern"
[ -f "/etc/passwd" ] && echo "File exists"
[ -d "$HOME" ] && echo "Directory exists"

# ANSI-C quoting
echo $'Hello\nWorld\t!\x21'

# Arithmetic
((result = 5 + 3 * 2))
echo "Result: $result"

# Exported functions
export -f greet

# Trap signals
trap 'echo "Interrupted!"' INT

# Source other scripts
source ~/.bashrc 2>/dev/null || true

# Exit with status
exit 0
SHELL

# Try different formatters
formatters = ["html", "terminal", "terminal256", "json", "plain"]

formatters.each do |formatter_name|
  puts "\n" + "=" * 50
  puts "Using #{formatter_name} formatter:"
  puts "=" * 50

  begin
    output = Obelisk.highlight(shell_code, "shell", formatter_name, "monokai")

    case formatter_name
    when "html"
      # Show a snippet of the HTML output
      puts output.lines.first(20).join("\n")
      puts "... (truncated)"
    when "json"
      # Show first few tokens
      tokens = JSON.parse(output).as_a
      puts "First 10 tokens:"
      tokens.first(10).each do |token|
        puts "  #{token}"
      end
      puts "... (#{tokens.size} total tokens)"
    else
      # Show full output for terminal formatters
      puts output
    end
  rescue ex
    puts "Error: #{ex.message}"
  end
end

# Test with different shell variants
puts "\n" + "=" * 50
puts "Testing shell variant detection:"
puts "=" * 50

variants = {
  "bash" => "#!/bin/bash\necho 'Bash script'",
  "sh"   => "#!/bin/sh\necho 'POSIX shell script'",
  "zsh"  => "#!/usr/bin/zsh\necho 'Zsh script'",
}

variants.each do |name, code|
  lexer = Obelisk.lexer(name)
  if lexer
    puts "✓ Found lexer for '#{name}'"
  else
    puts "✗ No lexer found for '#{name}'"
  end
end
