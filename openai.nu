# ChatGPT Response API

const PERSISTENCE = '.chat.json'
const INSTRUCTIONS = "prompt.instructions"
const URL = "https://api.openai.com/v1/responses"

def find-file-in-path [name: string] {
    mut parts = pwd | path split
    while ($parts | is-not-empty) {
        let maybe = $parts | str join '/' | path join $name
        if ($maybe | path exists) {
            return $maybe
        }
        $parts = $parts | drop
    }
}

def file-name [file: string] {
    $file | path parse | format pattern "{stem}.{extension}"
}

# Ask the model a question!

# This uses the Responses API to submit a request to the OpenAI model of choice.
# By default, it continues the conversation by including the last response.
# You can directly provide instructions in a file, or let it implicitly look
# up in prompt.instructions
export def ask [
    input?   # the prompt
    --debug  # inspect the request, don't submit
    --reparse # take existing .chat.json and parse the output
    --model (-m) = "gpt-5"
    --oneshot # do not use previous response - no conversation
    --file (-f): string # include a *text* file in the prompt
    --instructions (-i): string # your overall guiding prompt in a file
    --request (-r): record # any request overrides (https://platform.openai.com/docs/api-reference/responses)
] {
    let $pipe_in = $in # save the command's input (will get clobbered!)
    let inp = $input | default $pipe_in
    let instructions = $instructions | default { find-file-in-path $INSTRUCTIONS }
    let inp = if ($file | is-not-empty) {
        let file = $file | path expand  # for ~ etc
        let fname = file-name $file
        let contents = open -r $file
        $"# ($fname)\n\n```($contents)```\n\n($inp)"
    } else {
        $inp
    }
    let verbose = true
    let url = $URL
    let request = if ($request | is-empty) {
        {}
    } else {
        $request
    } | if ($instructions | is-not-empty) and $instructions != "none" {
        insert instructions (open -r $instructions)
    } else {
        $in
    }
    # By default, we give the API the last response received so we have a 'conversation'
    let last_response_id = if not $oneshot { 
        try {
            open $PERSISTENCE | get id
        }
    } else {
        null
    }
    # Merge this default request with any custom --request (which will overwrite)
    let payload = {
        model: $model
        input: $inp
        previous_response_id: $last_response_id
        tools: [{type: web_search}]
    } | merge $request
    let payload = $payload | to json
    if $debug { # we just want to check the request body first
        print $payload
        return
    }
    let resp = if not $reparse { 
        let resp = http post -t application/json -H {Authorization: $"Bearer ($env.OPENAI_API_KEY)"} $url $payload 
        $resp | save -f $PERSISTENCE
        $resp
    } else {
        open $PERSISTENCE
    }

    if ($resp | get error?| is-not-empty) {
        $resp.error
    } else {
        if $verbose {
            let usage = $resp.usage
            print -e $"(ansi g)input ($usage.input_tokens) cached ($usage.input_tokens_details.cached_tokens?) (ansi rst)"
            print -e $"(ansi g)output ($usage.output_tokens) reasoning ($usage.output_tokens_details.reasoning_tokens?) (ansi rst)" 
            print -e ''
        }
        mut out = ''
        for o in $resp.output {
            if $o.type == "message" {
                for c in $o.content {
                    if $c.type == "output_text" {
                        $out += $c.text
                    }
                }
            }
        }
        $out
    }    
}

