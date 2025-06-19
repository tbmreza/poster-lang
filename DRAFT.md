Pseudocode programming language.
Pseudocode expression tool. Algorithms-book-styled presentation as a general programming language.

Features:
- Time travel debugging: Record, replay, and full VM state examination at any point.
- Complexity aware: Optionally summarizes an algorithm's complexity.

Supporting projects:
- Literate programming, visual rendering, font ligatures
- Unit testing, golden tests
- Package manager loper
- LSP, MCP

```
StringCopy(s, n)
for i := 1 to n
	t[i] := s[i]
return t

output StringCopy("Poster", 255)
```


valueOfCoins := Sigma until d from k=1, (i index k) * (c index k)

sigma(d, k=1) ik ck

S d
S      i   c
S k=1   k   k


AllLeaves(L, k)
a := (1, ..., 1)
while forever
    output a
    a := Next(a, L, k)
    if a = (1, 1, ..., 1)
        done

AllLeaves/2 line 6

output AllLeaves([], 0)

AllLeaves([], 0) for example is []
  (*  "concrete interpreter"
  CPS/cps.sml requires grammar/parser.sml for parsePath : Path -> ast
  CPS/cps.sml provides                        ioInterp : value -> IO ()
  cli.sml requires ioInterp, for example `ioInterp (cps "#output 12")`
*)
# poster-lang

- [ ] Define the message format for StepResult or StateSnapshot.
- [ ] Set up a JS/HTML to talk to the interpreter, playback and UI update loop.
- [ ] Write the core interpreter (with step+state).  cps conversion
- [ ] Self hosting compiler

StateSnapshot
    registers
    callstack


encoding constructs like if-statement, for-loop, let-binding can take form in lambda calculus or
source-to-source transpiler.
neither can be the way to go if we want time-travel at the level of *line of code*, we need a
full interpreter that manages stack/heap well.
which is why after the data model and the UI model take form, the core interpreter will
likely be in zig. anything but the core interpreter will be in sml.

but we don't want loc time-travel. let's learn cps conversion first.

for our time-travel support purposes, we'll start with list-based Env instead of hashmaps. we'll
explore hybrid implementation in time.

at the beginning of the execution, env is minimal, the continuation is the whole program.
when the execution halts, env normally has grown larger, the continuation is identity function.
stepping back means popping [history], stepping forward means proceeding cps to expr

## See also
- https://visualgo.net/en

```
// Create your own language definition here
// You can safely look at other samples without losing modifications.
// Modifications are not saved on browser refresh/close though -- copy often!
return {
  // Set defaultToken to invalid to see what you do not tokenize yet
  // defaultToken: 'invalid',

  keywords: [
    'abstract', 'continue', 'for', 'new', 'switch', 'assert', 'goto', 'do',
    'if', 'private', 'this', 'break', 'protected', 'throw', 'else', 'public',
    'enum', 'return', 'catch', 'try', 'interface', 'static', 'class',
    'finally', 'const', 'super', 'while', 'true', 'false'
  , 'to'
  , 'output'
  , "downto"
  ],

  typeKeywords: [
    'boolean', 'double', 'byte', 'int', 'short', 'char', 'void', 'long', 'float'
  ],

  operators: [
    '=', '>', '<', '!', '~', '?', ':', '==', '<=', '>=', '!=',
    '&&', '||', '++', '--', '+', '-', '*', '/', '&', '|', '^', '%',
    '<<', '>>', '>>>', '+=', '-=', '*=', '/=', '&=', '|=', '^=',
    '%=', '<<=', '>>=', '>>>='
  ],

  // we include these common regular expressions
  symbols:  /[=><!~?:&|+\-*\/\^%]+/,

  // C# style strings
  escapes: /\\(?:[abfnrtv\\"']|x[0-9A-Fa-f]{1,4}|u[0-9A-Fa-f]{4}|U[0-9A-Fa-f]{8})/,

  // The main tokenizer for our languages
  tokenizer: {
    root: [
      // identifiers and keywords
      [/[a-z_$][\w$]*/, { cases: { '@typeKeywords': 'keyword',
                                   '@keywords': 'keyword',
                                   '@default': 'identifier' } }],
      [/[A-Z][\w\$]*/, 'type.identifier' ],  // to show class names nicely

      // whitespace
      { include: '@whitespace' },

      // delimiters and operators
      [/[{}()\[\]]/, '@brackets'],
      [/[<>](?!@symbols)/, '@brackets'],
      [/@symbols/, { cases: { '@operators': 'operator',
                              '@default'  : '' } } ],

      // @ annotations.
      // As an example, we emit a debugging log message on these tokens.
      // Note: message are supressed during the first load -- change some lines to see them.
      [/@\s*[a-zA-Z_\$][\w\$]*/, { token: 'annotation', log: 'annotation token: $0' }],

      // numbers
      [/\d*\.\d+([eE][\-+]?\d+)?/, 'number.float'],
      [/0[xX][0-9a-fA-F]+/, 'number.hex'],
      [/\d+/, 'number'],

      // delimiter: after number because of .\d floats
      [/[;,.]/, 'delimiter'],

      // strings
      [/"([^"\\]|\\.)*$/, 'string.invalid' ],  // non-teminated string
      [/"/,  { token: 'string.quote', bracket: '@open', next: '@string' } ],

      // characters
      [/'[^\\']'/, 'string'],
      [/(')(@escapes)(')/, ['string','string.escape','string']],
      [/'/, 'string.invalid'],

      [/#\{/, 'comment', '@comment'],
      [/\/\/.*$/, 'comment'],
      [/[{}]/, 'delimiter.bracket'],
      [/\d+/, 'number'],
      [/[a-z_$][\w$]*/, 'identifier'],

    ],

    comment: [
      [/#\{/, 'comment', '@comment'],  // enter nested block comment
      [/}#/, 'comment', '@pop'],       // exit current block comment
      [/[^#{}]+/, 'comment'],
      [/./, 'comment'],                // match any single character to avoid getting stuck
    ],

    // comment: [
    //   [/[^\/*]+/, 'comment' ],
    //   [/\/\*/,    'comment', '@push' ],    // nested comment
    //   ["\\*/",    'comment', '@pop'  ],
    //   [/[\/*]/,   'comment' ]
    // ],



    string: [
      [/[^\\"]+/,  'string'],
      [/@escapes/, 'string.escape'],
      [/\\./,      'string.escape.invalid'],
      [/"/,        { token: 'string.quote', bracket: '@close', next: '@pop' } ]
    ],
    // whitespace: [
    //   [/[ \t\r\n]+/, 'white'],
    //   [/\/\*/,       'comment', '@comment' ],
    //   // [/\/\*/,       'comment', '@comment' ],
    //   // [/\/\/.*$/,    'comment'],
    //   [/--.*$/,    'comment'],
    // ],

    whitespace: [
      [/[ \t\r\n]+/, 'white'],
      // [/#{/,       'comment', '@comment' ],
      // [/{#.*$/,    'comment'],
      [/--.*$/,    'comment'],
      [/\.\..*$/,    'comment'],
    ],
  },
};
```


# logicmon
Logic program application that monitors subject language source to analyze it incrementally.




- tree-sitter-utlc: ast util and syntax highlight
- incremental-analyzer-web: monaco editor web frontend app
- logicmon: logic program as an rpc service that monitors subject language source to analyze it incrementally
- logicmon-nvim: 
- logicmon-dx-web: 
dioxus web
Render directly to the DOM using WebAssembly
Pre-render with SSR and rehydrate on the client

## Testing
```
cargo r                   # start rpc server in one terminal session/pane...
cargo r --example client  # ...fire request from example client
cargo r --example dl
```


// example/client.rs
use ts_proto::zer_client::ZerClient;
use ts_proto::*;

pub mod ts_proto {
    tonic::include_proto!("ts");
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut client = ZerClient::connect("http://[::1]:50051").await?;

    let request = tonic::Request::new(Source {
        val: String::from("fn test(a: u32) {}"),
        // val: String::from("fn testttttttttttttt(a: u32) {}"),
    });

    let response = client.replace(request).await?;

    println!("RESPONSE={:?}", response);

    Ok(())
}


??
disable tonic transport feature
leptos debug, name it logicmon-play
logicmon-play borked trying the following:
if https://github.com/devashishdxt/tonic-web-wasm-client doesn't work, use ace editor and axum (rest http)
```
cd interlocut
cargo r

cd interlocut/web-editor
npm run dev  # npm run build:release in build.rs is an idea
```

## Status
Work in progress. Everything outside interlocut folder are old drafts.


claude:
// Time Travel Debugging with Continuation Passing Style
// Core data structures and algorithms

// Continuation represents "what happens next" + program state
struct Continuation {
    function: Function,           // The function to call next
    args: List,                  // Arguments for the function
    environment: Environment,     // Variable bindings at this point
    call_stack: CallStack,       // Stack trace for debugging
    timestamp: Time,             // When this continuation was created
    parent: Continuation?        // Previous continuation (forms history chain)
}

// Time travel debugger state
struct TimeDebugger {
    history: List<Continuation>,     // All captured continuations
    current_index: Integer,          // Current position in history
    breakpoints: Set<Location>,      // Active breakpoints
    watches: Map<Variable, Value>    // Watched variables
}

// Transform regular function to CPS form
function cps_transform(expr, cont) {
    match expr {
        // Simple value - just pass to continuation
        Value(v) -> 
            cont(v)
            
        // Variable lookup
        Variable(name) ->
            value = environment.lookup(name)
            cont(value)
            
        // Function application becomes nested CPS calls
        Application(func, args) ->
            cps_transform(func, lambda f ->
                cps_transform_args(args, lambda arg_values ->
                    // CAPTURE POINT: Save continuation before function call
                    save_continuation(lambda result -> cont(result))
                    f.apply(arg_values, cont)
                )
            )
            
        // Let binding
        Let(var, value_expr, body_expr) ->
            cps_transform(value_expr, lambda value ->
                old_env = environment
                environment.bind(var, value)
                cps_transform(body_expr, lambda result ->
                    environment = old_env  // Restore environment
                    cont(result)
                )
            )
    }
}

// Core time travel operations
function save_continuation(cont) {
    snapshot = Continuation {
        function: cont,
        args: current_args,
        environment: environment.clone(),
        call_stack: call_stack.clone(), 
        timestamp: now(),
        parent: debugger.current_continuation()
    }
    
    debugger.history.append(snapshot)
    debugger.current_index = debugger.history.length - 1
    
    // Check for breakpoints or watches
    if should_break(snapshot) {
        enter_debug_mode(snapshot)
    }
}

// Time travel: jump to any point in execution history
function time_travel_to(index) {
    if index < 0 or index >= debugger.history.length {
        error("Invalid time travel index")
    }
    
    target_continuation = debugger.history[index]
    debugger.current_index = index
    
    // Restore complete program state
    environment = target_continuation.environment.clone()
    call_stack = target_continuation.call_stack.clone()
    
    // Resume execution from this point
    target_continuation.function(target_continuation.args)
}

// Advanced time travel: conditional jumps
function time_travel_when(predicate) {
    for i in reverse(0 to debugger.current_index) {
        cont = debugger.history[i]
        if predicate(cont.environment, cont.call_stack) {
            time_travel_to(i)
            return
        }
    }
    print("No matching state found")
}

// Example: Fibonacci with time travel debugging
function fib_cps(n, cont) {
    // Save state before each recursive call
    save_continuation(cont)
    
    if n <= 1 {
        cont(n)
    } else {
        fib_cps(n - 1, lambda x ->
            fib_cps(n - 2, lambda y ->
                cont(x + y)
            )
        )
    }
}

// Debugger command interface
function debug_repl() {
    while true {
        command = read_command()
        match command {
            "step" -> 
                step_forward()
                
            "back" -> 
                step_backward()
                
            "goto <n>" ->
                time_travel_to(n)
                
            "when <condition>" ->
                time_travel_when(parse_condition(condition))
                
            "history" ->
                print_execution_history()
                
            "watch <var>" ->
                add_watch_variable(var)
                
            "break <location>" ->
                add_breakpoint(location)
                
            "timeline" ->
                visualize_execution_timeline()
                
            "diff <i> <j>" ->
                show_state_diff(i, j)
                
            "replay <start> <end>" ->
                replay_execution_segment(start, end)
                
            "fork" ->
                create_speculative_branch()
                
            "quit" ->
                break
        }
    }
}

// Advanced features enabled by CPS approach

// 1. Speculative execution: try different code paths
function speculative_execute(alternative_expr) {
    current_state = debugger.current_continuation()
    saved_history = debugger.history.clone()
    
    // Execute alternative in isolated context  
    result = cps_transform(alternative_expr, identity)
    
    print("Speculative result:", result)
    print("Would you like to commit this change? (y/n)")
    
    if read_input() != "y" {
        // Rollback to original state
        debugger.history = saved_history
        time_travel_to(debugger.current_index)
    }
}

// 2. Reverse execution: undo operations
function step_backward() {
    if debugger.current_index > 0 {
        debugger.current_index -= 1
        cont = debugger.history[debugger.current_index]
        
        // Show what changed
        if debugger.current_index < debugger.history.length - 1 {
            next_cont = debugger.history[debugger.current_index + 1]
            show_diff(cont.environment, next_cont.environment)
        }
        
        // Restore state but don't execute
        environment = cont.environment.clone()
        call_stack = cont.call_stack.clone()
    }
}

// 3. Causal analysis: find what caused a bug
function find_cause_of_bug(error_condition) {
    bug_index = find_first_occurrence(error_condition)
    
    // Walk backwards through causality chain
    for i in reverse(0 to bug_index) {
        cont = debugger.history[i]
        
        // Check if this state change contributed to the bug
        if could_cause(cont, error_condition) {
            highlight_potential_cause(cont)
        }
    }
}

// 4. Performance time travel: jump to expensive operations
function profile_time_travel() {
    expensive_operations = []
    
    for i in 0 to debugger.history.length {
        cont = debugger.history[i]
        if cont.timestamp - previous_timestamp > SLOW_THRESHOLD {
            expensive_operations.append((i, cont))
        }
    }
    
    print("Expensive operations found:")
    for (index, cont) in expensive_operations {
        print(f"  {index}: {cont.function} ({cont.timestamp}ms)")
    }
}

// Key insight: CPS makes time travel natural because:
// 1. Every computation step creates a continuation (checkpoint)
// 2. Continuations capture complete program state
// 3. Jumping to any continuation restores exact state
// 4. The continuation chain forms a complete execution history
// 5. Advanced debugging features emerge naturally from this structure
