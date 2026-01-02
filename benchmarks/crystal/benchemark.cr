require "benchmark"
require "../../src/obelisk"

module Obelisk::Benchmarks
  # Test file metadata
  struct TestFile
    property path : String
    property language : String
    property name : String

    def initialize(@path, @language, @name)
    end

    def source : String
      File.read(@path)
    end

    def size_kb : Float64
      File.size(@path) / 1024.0
    end
  end

  # Benchmark result for a single file
  struct Result
    property name : String
    property language : String
    property size_kb : Float64
    property time_ms : Float64
    property throughput_mb_s : Float64
    property latency_ms : Float64

    def initialize(@name, @language, @size_kb, @time_ms, @throughput_mb_s, @latency_ms)
    end

    def to_csv(io : IO)
      io << name << ","
      io << language << ","
      io << size_kb << ","
      io << time_ms << ","
      io << throughput_mb_s << ","
      io << latency_ms << "\n"
    end

    def self.header(io : IO)
      io << "File,Language,Size(KB),Time(ms),Throughput(MB/s),Latency(ms)\n"
    end
  end

  # Load all test files from the data directory
  def self.load_test_files(data_dir : String) : Array(TestFile)
    files = [] of TestFile

    # Map of directory names to Obelisk language names
    lang_map = {
      "javascript" => "javascript",
      "python"     => "python",
      "json"       => "json",
      "yaml"       => "yaml",
      "ruby"       => "ruby",
      "go"         => "go",
      "rust"       => "rust",
      "html"       => "html",
      "css"        => "css",
      "sql"        => "sql",
      "shell"      => "shell",
    }

    lang_map.each do |dir, lang|
      pattern = File.join(data_dir, dir, "*")
      Dir.glob(pattern).each do |path|
        next if File.directory?(path)
        name = "#{dir}/#{File.basename(path)}"
        files << TestFile.new(path, lang, name)
      end
    end

    files.sort_by!(&.size_kb)
    files
  end

  # Measure latency to first token
  def self.measure_latency(source : String, language : String) : Float64
    lexer = Obelisk.lexer(language)
    return 0.0 unless lexer

    start = Time.monotonic
    iterator = lexer.tokenize(source)
    first_token = iterator.next
    latency = (Time.monotonic - start).total_milliseconds

    latency
  end

  # Run benchmarks on all test files
  def self.run(data_dir : String = File.join(__DIR__, "../data"))
    files = load_test_files(data_dir)

    if files.empty?
      puts "No test files found in #{data_dir}"
      puts "Run ./scripts/fetch_benchmark_data.sh first"
      return
    end

    puts "Obelisk Benchmark Suite"
    puts "=" * 80
    puts "Found #{files.size} test files\n"

    results = [] of Result

    iterations = 10

    files.each do |file|
      source = file.source
      size_kb = file.size_kb

      # Warmup
      3.times { Obelisk.highlight(source, file.language) }

      # Measure latency (single run)
      latency = measure_latency(source, file.language)

      # Measure execution time
      total_time = 0.0

      iterations.times do
        elapsed = Time.measure do
          Obelisk.highlight(source, file.language)
        end
        total_time += elapsed.total_milliseconds
      end

      avg_time_ms = total_time / iterations
      throughput_mb_s = (size_kb / 1024.0) / (avg_time_ms / 1000.0)

      results << Result.new(
        file.name,
        file.language,
        size_kb,
        avg_time_ms,
        throughput_mb_s,
        latency
      )

      puts "✓ #{file.name.ljust(30)} (#{size_kb.round(1).to_s.rjust(6)} KB) - #{avg_time_ms.round(3)} ms"
    end

    # Print CSV output to stdout
    puts "\n" + "=" * 80
    puts "Results (CSV format):"
    puts "=" * 80
    puts "File,Language,Size(KB),Time(ms),Throughput(MB/s),Latency(ms)"
    results.each do |r|
      puts "#{r.name},#{r.language},#{r.size_kb},#{r.time_ms},#{r.throughput_mb_s},#{r.latency_ms}"
    end

    # Print summary statistics
    puts "\nSummary:"
    puts "-" * 80
    avg_time = results.map(&.time_ms).sum / results.size
    avg_throughput = results.map(&.throughput_mb_s).sum / results.size
    avg_latency = results.map(&.latency_ms).sum / results.size

    puts "Average time:       #{avg_time.round(3)} ms"
    puts "Average throughput: #{avg_throughput.round(2)} MB/s"
    puts "Average latency:    #{avg_latency.round(3)} ms"
  end
end

Obelisk::Benchmarks.run
