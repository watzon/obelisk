# Known Issues

## Crystal Compiler Bug: Iterator Composition

### Issue
There's a known Crystal compiler bug (#14317) that affects iterator composition in certain scenarios. This manifests as:
- "Process hit a breakpoint and no debugger was attached" errors in specs
- "Invalid memory access (signal 11)" errors during runtime
- Arithmetic overflow errors when calling `.to_a` on composed iterators

### Affected Code
The issue primarily affects `ComposedLexer` when:
1. Multiple lexers are composed together
2. The `tokenize` method returns an iterator through multiple method calls
3. `.to_a` is called on the resulting iterator

### Workaround
The affected test in `spec/composition_spec.cr` is marked as `pending`. The functionality works correctly when:
- Using iterators directly without `.to_a`
- Running outside the spec framework
- Using alternative patterns that avoid deep iterator composition

### Alternative Implementations
If you need to use composed lexers with `.to_a`, consider:
1. Eagerly evaluating tokens into an array and wrapping with a simple iterator
2. Using the iterator with `each` or manual iteration instead of `.to_a`
3. Implementing custom iterators that avoid the problematic composition patterns

### References
- Crystal Issue #14317: https://github.com/crystal-lang/crystal/issues/14317
- Related issues: #13037, #14154, #5694

### Status
This is a Crystal compiler issue that needs to be fixed upstream. Until then, the workarounds mentioned above should be used.