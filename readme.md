# OpenAI Responses Client for Nushell

Just set `OPENAI_API_KEY` and `use <path>/openai.nu *`

```
 help ask
This uses the Responses API to submit a request to the OpenAI model of choice.
By default, it continues the conversation by including the last response.
You can directly provide instructions in a file, or let it implicitly look
up in prompt.instructions. First set $env.OPENAI_API_KEY

Usage:
  > ask {flags} (input) 

Flags:
  --debug: inspect the request, don't submit
  --reparse: take existing .chat.json and parse the output
  -m, --model <string>: set model (default is gpt-5) or use $env.OPENAI_MODEL
  --oneshot: do not use previous response - no conversation
  -f, --file <string>: include a *text* file in the prompt
  -i, --instructions <string>: your overall guiding prompt in a file
  -r, --request <record>: any request overrides (https://platform.openai.com/docs/api-reference/responses)
  -h, --help: Display the help message for this command

Parameters:
  input <any>: the prompt (optional)

Input/output types:
   #   input   output 
  ────────────────────
   0   any     any    

```

Given these instructions (`prompt.instructions`):

```
you are a Nushell expert. Try to give a single suggestion, 
without unnecessary explanation
```

This is what it thinks of itself:

```nushell
> ask 'Explain the ask command, including what environment variables it depends on' -m gpt-4.1 -f openai.nu
input 2319 cached 1152 
output 86 reasoning 0 

The `ask` command sends a text prompt to the OpenAI responses API,
optionally using previous conversation context, instructions from a file,
a specified model, or additional input from a text file, and it saves responses for future context.
It depends on the environment variables `$env.OPENAI_API_KEY` (required) and
optionally `$env.OPENAI_MODEL` (if not set, defaults to "gpt-5").
/work/dev/openai.nu> ask 'Given this `ask` command, how can we make it into an interactive chat command?'
input 2429 cached 0 
output 40 reasoning 0 

Wrap `ask` in a loop that repeatedly prompts the user for input, calls `ask` with that input, and prints the response, until the user enters "exit" or similar.
/work/dev/openai.nu> ask 'Write this command'
input 2478 cached 2176 
output 91 reasoning 0 

def chat [
    --model(-m): string
    --instructions(-i): string
] {
    print "Entering Chat (type 'exit' to quit):"
    loop {
        let user_input = (input "You: ")
        if $user_input == "exit" { break }
        let response = ask $user_input --model $model --instructions $instructions
        print $"AI: ($response)"
    }
}

```

(This works, BTW)

By default, it continues the conversation by including the last response. The total
response afterwards is always in `.chat.json`, so if you need to reset the conversation
then just delete this file, or just say `--oneshot` to not send the last response id.

```nushell
> ask 'Give me a command to run a given command over all markdown files in a directory' -m gpt-4.1
input 339 cached 0
output 21 reasoning 0

ls *.md | each { |it| your-command $it.name }

```

`gpt-4.1` (the best non-reasoning model) is much faster, but a bit stupid compared 
to `gpt-5` which will think things through. But it can do pretty well, especially
if we aren't asking complicated questions. (I'm personally currently defaulting to
`gpt-4.1` unless the problem requires harder thinking.)

```nushell
> ask 'Give me a command to run a given command over all markdown files in a directory' -m gpt-4.1
input 339 cached 0
output 21 reasoning 0

ls *.md | each { |it| your-command $it.name }

> ask 'unicode for check mark and error cross?' -m gpt-4.1
input 374 cached 0
output 29 reasoning 0
Check mark: `✔️` (`U+2714`)
Error cross: `❌` (`U+274C`)
```

## Future

This is about a hundred lines of fairly straightforward code. I do know about
[ai.nu](https://github.com/fj0r/ai.nu) but it broke in strange ways and obviously
never had been tested on Windows. Since I was interested in learning the Responses API
it was easier to write a little client from scratch.

Of course, I am tempted to add more interesting actions (like the ability to run
nushell code) but that is for another day.



