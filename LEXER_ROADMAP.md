# Obelisk Lexer Implementation Roadmap

This document tracks our progress implementing lexers to match the comprehensive language support provided by Chroma. Our goal is to support all languages that Chroma supports, implemented natively in Crystal.

## Current Status

- [x] **Crystal** *(Implemented)* - `.cr` - *Native Crystal syntax support*
- [x] **JSON** *(Implemented)* - `.json` - *Complete JSON syntax*
- [x] **YAML** *(Implemented)* - `.yml`, `.yaml` - *YAML syntax with documents, anchors, tags*
- [x] **Plain Text** *(Implemented)* - *Fallback lexer*

**Total Progress: 4/281 lexers (1.4%)**

---

## Programming Languages

### **A**
- [ ] **ABAP** *(XML-defined)* - `.abap`
- [ ] **ActionScript** *(XML-defined)* - `.as`
- [ ] **ActionScript 3** *(XML-defined)* - `.as`
- [ ] **Ada** *(XML-defined)* - `.adb`, `.ads`
- [ ] **Agda** *(XML-defined)* - `.agda`
- [ ] **AL** *(XML-defined)*
- [ ] **Alloy** *(XML-defined)* - `.als`
- [ ] **Angular2** *(XML-defined)*
- [ ] **APL** *(XML-defined)* - `.apl`
- [ ] **AppleScript** *(XML-defined)* - `.applescript`
- [ ] **Arduino** *(XML-defined)* - `.ino`
- [ ] **AutoHotkey** *(XML-defined)* - `.ahk`
- [ ] **AutoIt** *(XML-defined)* - `.au3`
- [ ] **Awk** *(XML-defined)* - `.awk`

### **B**
- [ ] **Ballerina** *(XML-defined)* - `.bal`
- [ ] **BlitzBasic** *(XML-defined)* - `.bb`
- [ ] **BQN** *(XML-defined)* - `.bqn`
- [ ] **Brainfuck** *(XML-defined)* - `.bf`

### **C**
- [ ] **C** *(XML-defined)* - `.c`, `.h`
- [ ] **C#** *(XML-defined)* - `.cs`
- [ ] **C++** *(XML-defined)* - `.cpp`, `.cc`, `.cxx`, `.hpp`
- [ ] **Ceylon** *(XML-defined)* - `.ceylon`
- [ ] **ChaiScript** *(XML-defined)* - `.chai`
- [ ] **Chapel** *(XML-defined)* - `.chpl`
- [ ] **Clojure** *(XML-defined)* - `.clj`, `.cljs`
- [ ] **COBOL** *(XML-defined)* - `.cob`, `.cbl`
- [ ] **CoffeeScript** *(XML-defined)* - `.coffee`
- [ ] **Common Lisp** *(Go-defined)* - `.lisp`, `.cl` - *Custom lexer due to complex syntax*
- [ ] **Coq** *(XML-defined)* - `.v`
- [x] **Crystal** *(Implemented)* - `.cr` - *Native Crystal syntax support*
- [ ] **Cython** *(XML-defined)* - `.pyx`

### **D**
- [ ] **D** *(XML-defined)* - `.d`
- [ ] **Dart** *(XML-defined)* - `.dart`
- [ ] **Dylan** *(XML-defined)* - `.dylan`

### **E**
- [ ] **Elixir** *(XML-defined)* - `.ex`, `.exs`
- [ ] **Elm** *(XML-defined)* - `.elm`
- [ ] **EmacsLisp** *(Go-defined)* - `.el` - *Custom lexer for Emacs-specific features*
- [ ] **Erlang** *(XML-defined)* - `.erl`

### **F**
- [ ] **Factor** *(XML-defined)* - `.factor`
- [ ] **Fennel** *(XML-defined)* - `.fnl`
- [ ] **Forth** *(XML-defined)* - `.forth`
- [ ] **Fortran** *(XML-defined)* - `.f`, `.f90`, `.f95`
- [ ] **FortranFixed** *(XML-defined)* - `.f`, `.for`
- [ ] **FSharp** *(XML-defined)* - `.fs`

### **G**
- [ ] **GAS** *(XML-defined)* - `.s`
- [ ] **GDScript** *(XML-defined)* - `.gd`
- [ ] **Gleam** *(XML-defined)* - `.gleam`
- [ ] **GLSL** *(XML-defined)* - `.glsl`, `.vert`, `.frag`
- [ ] **Go** *(Go-defined)* - `.go` - *Custom lexer with Go template support*
- [ ] **Go HTML Template** *(Go-defined)* - *Delegating lexer combining HTML + Go templates*
- [ ] **Go Text Template** *(Go-defined)* - *Go template syntax*
- [ ] **GraphQL** *(XML-defined)* - `.graphql`
- [ ] **Groovy** *(XML-defined)* - `.groovy`

### **H**
- [ ] **Hare** *(XML-defined)* - `.ha`
- [ ] **Haskell** *(XML-defined)* - `.hs`
- [ ] **Haxe** *(Go-defined)* - `.hx` - *Custom lexer for complex syntax features*
- [ ] **HLSL** *(XML-defined)* - `.hlsl`
- [ ] **HolyC** *(XML-defined)* - `.hc`
- [ ] **Hy** *(XML-defined)* - `.hy`

### **I**
- [ ] **Idris** *(XML-defined)* - `.idr`
- [ ] **Igor** *(XML-defined)* - `.ipf`
- [ ] **Io** *(XML-defined)* - `.io`

### **J**
- [ ] **J** *(XML-defined)* - `.ijs`
- [ ] **Java** *(XML-defined)* - `.java`
- [ ] **JavaScript** *(XML-defined)* - `.js`
- [ ] **Jsonnet** *(XML-defined)* - `.jsonnet`
- [ ] **Julia** *(XML-defined)* - `.jl`
- [ ] **Jungle** *(XML-defined)*

### **K**
- [ ] **Kotlin** *(XML-defined)* - `.kt`

### **L**
- [ ] **Lean** *(XML-defined)* - `.lean`
- [ ] **LLVM** *(XML-defined)* - `.ll`
- [ ] **Lua** *(XML-defined)* - `.lua`

### **M**
- [ ] **Mathematica** *(XML-defined)* - `.m`, `.nb`
- [ ] **Matlab** *(XML-defined)* - `.m`
- [ ] **Metal** *(XML-defined)* - `.metal`
- [ ] **MiniZinc** *(XML-defined)* - `.mzn`
- [ ] **MLIR** *(XML-defined)* - `.mlir`
- [ ] **Modula-2** *(XML-defined)* - `.mod`
- [ ] **Mojo** *(XML-defined)* - `.mojo`, `.🔥`
- [ ] **MonkeyC** *(XML-defined)* - `.mc`
- [ ] **MorrowindScript** *(XML-defined)*

### **N**
- [ ] **NASM** *(XML-defined)* - `.asm`
- [ ] **Natural** *(XML-defined)*
- [ ] **Newspeak** *(XML-defined)*
- [ ] **Nim** *(XML-defined)* - `.nim`

### **O**
- [ ] **Objective-C** *(XML-defined)* - `.m`, `.mm`
- [ ] **OCaml** *(XML-defined)* - `.ml`, `.mli`
- [ ] **Octave** *(XML-defined)* - `.m`
- [ ] **Odin** *(XML-defined)* - `.odin`
- [ ] **OnesEnterprise** *(XML-defined)*
- [ ] **OpenEdge ABL** *(XML-defined)* - `.p`
- [ ] **OpenSCAD** *(XML-defined)* - `.scad`

### **P**
- [ ] **Perl** *(XML-defined)* - `.pl`, `.pm`
- [ ] **PHP** *(Go-defined)* - `.php` - *Custom lexer for embedded HTML support*
- [ ] **PHTML** *(XML-defined)* - `.phtml`
- [ ] **Pig** *(XML-defined)* - `.pig`
- [ ] **PL/pgSQL** *(XML-defined)* - `.sql`
- [ ] **Plutus Core** *(XML-defined)*
- [ ] **Pony** *(XML-defined)* - `.pony`
- [ ] **PostScript** *(XML-defined)* - `.ps`
- [ ] **PowerQuery** *(XML-defined)* - `.pq`
- [ ] **PowerShell** *(XML-defined)* - `.ps1`
- [ ] **Prolog** *(XML-defined)* - `.pl`
- [ ] **PRQL** *(XML-defined)* - `.prql`
- [ ] **PSL** *(XML-defined)*
- [ ] **Puppet** *(XML-defined)* - `.pp`
- [ ] **Python** *(XML-defined)* - `.py`, `.pyw`, `.pyi`
- [ ] **Python 2** *(XML-defined)* - `.py`

### **Q**
- [ ] **QBasic** *(XML-defined)* - `.bas`
- [ ] **QML** *(XML-defined)* - `.qml`

### **R**
- [ ] **R** *(XML-defined)* - `.r`, `.R`
- [ ] **Racket** *(XML-defined)* - `.rkt`
- [ ] **Ragel** *(XML-defined)* - `.rl`
- [ ] **Raku** *(Go-defined)* - `.raku`, `.pl6` - *Custom lexer for complex regex and syntax features*
- [ ] **react** *(XML-defined)* - `.jsx`
- [ ] **ReasonML** *(XML-defined)* - `.re`
- [ ] **Rego** *(XML-defined)* - `.rego`
- [ ] **Rexx** *(XML-defined)* - `.rexx`
- [ ] **Ruby** *(XML-defined)* - `.rb`
- [ ] **Rust** *(XML-defined)* - `.rs`

### **S**
- [ ] **SAS** *(XML-defined)* - `.sas`
- [ ] **Scala** *(XML-defined)* - `.scala`
- [ ] **Scheme** *(XML-defined)* - `.scm`
- [ ] **Scilab** *(XML-defined)* - `.sci`
- [ ] **Smali** *(XML-defined)* - `.smali`
- [ ] **Smalltalk** *(XML-defined)* - `.st`
- [ ] **Solidity** *(XML-defined)* - `.sol`
- [ ] **SourcePawn** *(XML-defined)* - `.sp`
- [ ] **Standard ML** *(XML-defined)* - `.sml`
- [ ] **Svelte** *(Go-defined)* - `.svelte` - *Custom lexer for template syntax*
- [ ] **Swift** *(XML-defined)* - `.swift`
- [ ] **systemverilog** *(XML-defined)* - `.sv`

### **T**
- [ ] **TableGen** *(XML-defined)* - `.td`
- [ ] **Tal** *(XML-defined)*
- [ ] **TASM** *(XML-defined)* - `.asm`
- [ ] **Tcl** *(XML-defined)* - `.tcl`
- [ ] **Thrift** *(XML-defined)* - `.thrift`
- [ ] **TradingView** *(XML-defined)*
- [ ] **Turing** *(XML-defined)* - `.t`
- [ ] **TypeScript** *(XML-defined)* - `.ts`
- [ ] **TypoScript** *(Go-defined)* - `.ts` - *Custom lexer for TYPO3 configuration*
- [ ] **TypoScriptCssData** *(XML-defined)*
- [ ] **TypoScriptHtmlData** *(XML-defined)*

### **V**
- [ ] **V** *(XML-defined)* - `.v`
- [ ] **Vala** *(XML-defined)* - `.vala`
- [ ] **VB.net** *(XML-defined)* - `.vb`
- [ ] **verilog** *(XML-defined)* - `.v`
- [ ] **VHDL** *(XML-defined)* - `.vhd`
- [ ] **VimL** *(XML-defined)* - `.vim`
- [ ] **vue** *(XML-defined)* - `.vue`

### **W**
- [ ] **WDTE** *(XML-defined)*
- [ ] **WebGPU Shading Language** *(XML-defined)* - `.wgsl`
- [ ] **Whiley** *(XML-defined)* - `.whiley`

### **Z**
- [ ] **Z80 Assembly** *(XML-defined)* - `.z80`
- [ ] **Zed** *(Go-defined)* - `.zed` - *Custom lexer*
- [ ] **Zig** *(XML-defined)* - `.zig`

## Markup & Documentation Languages

- [ ] **HTML** *(Go-defined)* - `.html`, `.htm` - *Wrapper for XML lexer*
- [ ] **Markdown** *(Go-defined)* - `.md`, `.markdown` - *Custom lexer for enhanced features*
- [ ] **reStructuredText** *(Go-defined)* - `.rst` - *Custom lexer for Sphinx features*
- [ ] **XML** *(XML-defined)* - `.xml`
- [ ] **Org Mode** *(XML-defined)* - `.org`
- [ ] **TeX** *(XML-defined)* - `.tex`
- [ ] **Typst** *(XML-defined)* - `.typ`

## Template Languages

- [ ] **Cheetah** *(XML-defined)*
- [ ] **Django/Jinja** *(XML-defined)* - `.html`, `.jinja2`
- [ ] **Genshi** *(Go-defined)* - *Custom lexer for XML templates*
- [ ] **Genshi HTML** *(XML-defined)*
- [ ] **Genshi Text** *(XML-defined)*
- [ ] **Handlebars** *(XML-defined)* - `.hbs`
- [ ] **Mako** *(XML-defined)*
- [ ] **Mason** *(XML-defined)*
- [ ] **Myghty** *(XML-defined)*
- [ ] **Smarty** *(XML-defined)* - `.tpl`
- [ ] **Twig** *(XML-defined)*

## Configuration & Data Languages

- [ ] **ABNF** *(XML-defined)*
- [ ] **ANTLR** *(XML-defined)* - `.g4`
- [ ] **BibTeX** *(XML-defined)* - `.bib`
- [ ] **BNF** *(XML-defined)*
- [ ] **Caddyfile** *(Go-defined)* - `Caddyfile*` - *Custom lexer for complex syntax*
- [ ] **Caddyfile Directives** *(Go-defined)* - *Subset of Caddyfile syntax*
- [ ] **Cap'n Proto** *(XML-defined)* - `.capnp`
- [ ] **CMake** *(XML-defined)* - `CMakeLists.txt`, `.cmake`
- [ ] **CFEngine3** *(XML-defined)* - `.cf`
- [ ] **CSS** *(XML-defined)* - `.css`
- [ ] **Dax** *(XML-defined)*
- [ ] **Desktop Entry** *(XML-defined)* - `.desktop`
- [ ] **DTD** *(XML-defined)* - `.dtd`
- [ ] **EBNF** *(XML-defined)*
- [ ] **Gherkin** *(XML-defined)* - `.feature`
- [ ] **HCL** *(XML-defined)* - `.hcl`
- [ ] **HLB** *(XML-defined)*
- [ ] **INI** *(XML-defined)* - `.ini`
- [x] **JSON** *(Implemented)* - `.json` - *Complete JSON syntax*
- [ ] **Lighttpd configuration file** *(XML-defined)*
- [ ] **Makefile** *(XML-defined)* - `Makefile`, `.mk`
- [ ] **Meson** *(XML-defined)* - `meson.build`
- [ ] **Nginx configuration file** *(XML-defined)*
- [ ] **Nix** *(XML-defined)* - `.nix`
- [ ] **NSIS** *(XML-defined)* - `.nsi`
- [ ] **PacmanConf** *(XML-defined)* - `pacman.conf`
- [ ] **PkgConfig** *(XML-defined)* - `.pc`
- [ ] **properties** *(XML-defined)* - `.properties`
- [ ] **Protocol Buffer** *(XML-defined)* - `.proto`
- [ ] **reg** *(XML-defined)* - `.reg`
- [ ] **RPMSpec** *(XML-defined)* - `.spec`
- [ ] **Sass** *(XML-defined)* - `.sass`
- [ ] **SCSS** *(XML-defined)* - `.scss`
- [ ] **SNBT** *(XML-defined)*
- [ ] **SquidConf** *(XML-defined)*
- [ ] **stas** *(XML-defined)*
- [ ] **Stylus** *(XML-defined)* - `.styl`
- [ ] **SYSTEMD** *(XML-defined)* - `.service`, `.timer`
- [ ] **Terraform** *(XML-defined)* - `.tf`
- [ ] **TOML** *(XML-defined)* - `.toml`
- [x] **YAML** *(Implemented)* - `.yml`, `.yaml` - *YAML syntax with documents, anchors, tags*
- [ ] **YANG** *(XML-defined)* - `.yang`

## Shell & Scripting Languages

- [ ] **Bash** *(XML-defined)* - `.sh`, `.bash`
- [ ] **Bash Session** *(XML-defined)*
- [ ] **Batchfile** *(XML-defined)* - `.bat`, `.cmd`
- [ ] **Fish** *(XML-defined)* - `.fish`
- [ ] **Sed** *(XML-defined)*
- [ ] **Tcsh** *(XML-defined)* - `.tcsh`
- [ ] **V shell** *(XML-defined)* - `.vsh`

## Database & Query Languages

- [ ] **ArangoDB AQL** *(XML-defined)*
- [ ] **Cassandra CQL** *(XML-defined)*
- [ ] **Materialize SQL dialect** *(XML-defined)*
- [ ] **MySQL** *(Go-defined)* - `.sql` - *Custom lexer for MySQL-specific syntax*
- [ ] **PostgreSQL SQL dialect** *(XML-defined)* - `.sql`
- [ ] **PromQL** *(XML-defined)*
- [ ] **SPARQL** *(XML-defined)* - `.sparql`
- [ ] **SQL** *(XML-defined)* - `.sql`
- [ ] **Transact-SQL** *(XML-defined)* - `.sql`

## Network & Protocol Languages

- [ ] **ApacheConf** *(XML-defined)* - `.conf`
- [ ] **dns** *(Go-defined)* - *Custom lexer for DNS zone files*
- [ ] **Docker** *(XML-defined)* - `Dockerfile*`
- [ ] **HTTP** *(Go-defined)* - *Custom lexer for HTTP protocol*
- [ ] **ISCdhcpd** *(XML-defined)*

## Specialized & Domain-Specific Languages

- [ ] **ArmAsm** *(XML-defined)* - `.s`
- [ ] **Bicep** *(XML-defined)* - `.bicep`
- [ ] **cfstatement** *(XML-defined)*
- [ ] **Diff** *(XML-defined)* - `.diff`, `.patch`
- [ ] **Gnuplot** *(XML-defined)* - `.gp`
- [ ] **Groff** *(XML-defined)*
- [ ] **Hexdump** *(XML-defined)*
- [ ] **MCFunction** *(XML-defined)* - `.mcfunction`
- [x] **plaintext** *(Implemented)* - *Fallback lexer*
- [ ] **POVRay** *(XML-defined)* - `.pov`
- [ ] **Promela** *(XML-defined)* - `.pml`
- [ ] **Sieve** *(XML-defined)* - `.sieve`
- [ ] **Snobol** *(XML-defined)*
- [ ] **Termcap** *(XML-defined)*
- [ ] **Terminfo** *(XML-defined)*
- [ ] **Turtle** *(XML-defined)* - `.ttl`
- [ ] **VHS** *(XML-defined)* - `.tape`
- [ ] **Xorg** *(XML-defined)* - `.conf`

---

## Implementation Priority

### Phase 1: Popular Programming Languages (High Priority)
These are the most commonly used programming languages that should be implemented first:

- [ ] **Python** - Most popular language for many domains
- [ ] **JavaScript** - Web development essential
- [ ] **TypeScript** - Modern JavaScript with types
- [ ] **Java** - Enterprise and Android development
- [ ] **Go** - Cloud/backend development
- [ ] **Rust** - Systems programming
- [ ] **C** - Systems programming foundation
- [ ] **C++** - Systems and game development
- [ ] **C#** - Microsoft ecosystem
- [ ] **Ruby** - Web development and scripting
- [ ] **Swift** - iOS/macOS development
- [ ] **Kotlin** - Android development
- [ ] **Dart** - Flutter development
- [ ] **PHP** - Web backend development

### Phase 2: Popular Markup & Config Languages (High Priority)
Essential for web development and configuration:

- [ ] **HTML** - Web markup
- [ ] **XML** - Data interchange
- [ ] **Markdown** - Documentation
- [ ] **CSS** - Web styling
- [ ] **SCSS/Sass** - Enhanced CSS
- [ ] **TOML** - Configuration files
- [ ] **INI** - Configuration files
- [ ] **Dockerfile** - Container configuration

### Phase 3: Popular Shell & Database Languages (Medium Priority)
Important for DevOps and data work:

- [ ] **Bash** - Shell scripting
- [ ] **SQL** - Database queries
- [ ] **PowerShell** - Windows automation
- [ ] **Fish** - Modern shell

### Phase 4: Emerging & Modern Languages (Medium Priority)
Newer languages gaining popularity:

- [ ] **Zig** - Systems programming
- [ ] **V** - Fast compilation
- [ ] **Gleam** - Functional programming
- [ ] **Nim** - Python-like systems programming
- [ ] **Elixir** - Functional/concurrent programming
- [ ] **Haskell** - Pure functional programming

### Phase 5: Specialized Languages (Lower Priority)
Domain-specific and less common languages:

- [ ] All remaining languages based on specific needs

---

## Go-defined Lexers (Requiring Custom Implementation)

These lexers require custom Crystal code due to complex syntax, embedded languages, or special processing needs. They should be studied carefully:

1. **Caddyfile** + **Caddyfile Directives** - Complex configuration syntax
2. **Common Lisp** - Complex S-expression parsing
3. **DNS** - Zone file format specifics
4. **EmacsLisp** - Emacs-specific features
5. **Genshi** - XML template processing
6. **Go** + templates - Go template syntax integration
7. **Haxe** - Complex conditional compilation
8. **HTML** - Wrapper for embedded languages
9. **HTTP** - Protocol-specific parsing
10. **Markdown** - Enhanced markdown features
11. **MySQL** - MySQL-specific SQL syntax
12. **PHP** - Embedded HTML support
13. **Raku** - Complex regex and syntax features
14. **reStructuredText** - Sphinx integration
15. **Svelte** - Component template syntax
16. **TypoScript** - TYPO3 configuration format
17. **Zed** - Editor-specific format

---

## Implementation Notes

- **XML-defined lexers** (~261 lexers) can be translated more directly from Chroma's XML definitions
- **Go-defined lexers** (~20 lexers) require careful analysis of custom implementations
- **Priority should be given** to commonly used languages first
- **Template languages** may require delegating lexer support for embedded languages
- **Test coverage** should be maintained for all implemented lexers
- **Documentation** should be updated as each lexer is added

This roadmap provides a clear path to eventually support all languages that Chroma supports, making Obelisk a truly comprehensive syntax highlighting solution for Crystal applications.