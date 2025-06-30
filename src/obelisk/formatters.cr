require "./formatter"

# Register built-in formatters
Obelisk::Registry.formatters.register("html", Obelisk::HTMLFormatter.new)
Obelisk::Registry.formatters.register("html-classes", Obelisk::HTMLFormatter.new(with_classes: true))
Obelisk::Registry.formatters.register("terminal", Obelisk::ANSIFormatter.new)
Obelisk::Registry.formatters.register("text", Obelisk::PlainFormatter.new)
Obelisk::Registry.formatters.register("json", Obelisk::JSONFormatter.new)