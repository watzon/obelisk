#!/usr/bin/env crystal
# Compare Obelisk and Chroma benchmark results

module Compare
  struct Result
    property file : String
    property language : String
    property size_kb : Float64
    property time_ms : Float64
    property throughput_mb_s : Float64
    property latency_ms : Float64

    def initialize(@file, @language, @size_kb, @time_ms, @throughput_mb_s, @latency_ms)
    end

    def self.from_csv(row : Array(String))
      new(
        row[0],
        row[1],
        row[2].to_f,
        row[3].to_f,
        row[4].to_f,
        row[5].to_f
      )
    end
  end

  def self.load_results(path : String) : Hash(String, Result)
    results = {} of String => Result

    lines = File.read_lines(path)
    lines.skip(1).each do |line|  # Skip header
      parts = line.split(',')
      if parts.size >= 6
        result = Result.from_csv(parts)
        results[result.file] = result
      end
    end

    results
  end

  def self.run(obelisk_path : String, chroma_path : String)
    obelisk_results = load_results(obelisk_path)
    chroma_results = load_results(chroma_path)

    if obelisk_results.empty?
      puts "No Obelisk results found in #{obelisk_path}"
      return
    end

    if chroma_results.empty?
      puts "No Chroma results found in #{chroma_path}"
      return
    end

    # Find common files
    common_files = obelisk_results.keys & chroma_results.keys

    if common_files.empty?
      puts "No common test files between results"
      return
    end

    puts "Obelisk vs Chroma Benchmark Comparison"
    puts "=" * 100
    puts "\nExecution Time Comparison (lower is better):\n"

    time_faster = 0
    time_slower = 0

    common_files.each do |file|
      ob = obelisk_results[file]
      ch = chroma_results[file]

      ratio = ch.time_ms / ob.time_ms
      winner = ratio > 1 ? "Obelisk" : (ratio < 1 ? "Chroma" : "Tie")
      speedup = ratio > 1 ? "#{ratio.round(2)}x faster" : "#{(1.0 / ratio).round(2)}x slower"

      if ratio > 1
        time_faster += 1
      elsif ratio < 1
        time_slower += 1
      end

      puts sprintf("%-30s Obelisk: %6.3fms  Chroma: %6.3fms  | %s (%s)",
        file, ob.time_ms, ch.time_ms, winner, speedup)
    end

    puts "\n" + "-" * 100
    puts "Time Summary: Obelisk faster on #{time_faster} files, slower on #{time_slower} files"

    puts "\n\nLatency Comparison (lower is better):\n"

    latency_faster = 0
    latency_slower = 0

    common_files.each do |file|
      ob = obelisk_results[file]
      ch = chroma_results[file]

      ratio = ch.latency_ms / ob.latency_ms
      winner = ratio > 1 ? "Obelisk" : (ratio < 1 ? "Chroma" : "Tie")

      if ratio > 1
        latency_faster += 1
      elsif ratio < 1
        latency_slower += 1
      end

      puts sprintf("%-30s Obelisk: %6.3fms  Chroma: %6.3fms  | %s",
        file, ob.latency_ms, ch.latency_ms, winner)
    end

    puts "\n" + "-" * 100
    puts "Latency Summary: Obelisk faster on #{latency_faster} files, slower on #{latency_slower} files"

    puts "\n\nThroughput Comparison (higher is better):\n"

    common_files.each do |file|
      ob = obelisk_results[file]
      ch = chroma_results[file]

      ratio = ob.throughput_mb_s / ch.throughput_mb_s
      winner = ratio > 1 ? "Obelisk" : (ratio < 1 ? "Chroma" : "Tie")

      puts sprintf("%-30s Obelisk: %6.2f MB/s  Chroma: %6.2f MB/s  | %s",
        file, ob.throughput_mb_s, ch.throughput_mb_s, winner)
    end

    # Overall summary
    ob_avg_time = common_files.map { |f| obelisk_results[f].time_ms }.sum / common_files.size
    ch_avg_time = common_files.map { |f| chroma_results[f].time_ms }.sum / common_files.size
    ob_avg_latency = common_files.map { |f| obelisk_results[f].latency_ms }.sum / common_files.size
    ch_avg_latency = common_files.map { |f| chroma_results[f].latency_ms }.sum / common_files.size

    puts "\n" + "=" * 100
    puts "Overall Summary:\n"
    puts sprintf("Average Time:    Obelisk %.3fms  Chroma %.3fms  | %.2fx faster/slower",
      ob_avg_time, ch_avg_time, ch_avg_time / ob_avg_time)
    puts sprintf("Average Latency: Obelisk %.3fms  Chroma %.3fms  | %.2fx faster/slower",
      ob_avg_latency, ch_avg_latency, ch_avg_latency / ob_avg_latency)
  end
end

# Parse arguments
if ARGV.size != 2
  puts "Usage: compare.cr <obelisk_results.csv> <chroma_results.csv>"
  puts "\nGenerate results with:"
  puts "  crystal run benchmarks/crystal/benchemark.cr > obelisk.csv"
  puts "  cd benchmarks/go && go test -bench=. -benchmem > chroma.txt && go run main.go > ../chroma.csv"
  exit 1
end

Compare.run(ARGV[0], ARGV[1])
