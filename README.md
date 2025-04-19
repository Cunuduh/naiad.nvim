# naiad.nvim

a markdown-first neovim plugin for creative ideation and writing, with inline `[!...]` syntax triggers, ai-assisted reflection and interpretation using various providers like **ollama, openai, anthropic, and gemini**. like a naiad, it helps your writing flow.

**important**: this plugin requires a compatible ai backend service (like `ollama serve` or access to a cloud provider api) to be running or accessible. it communicates via http requests.

## features

-   **inline triggers**: use `[!your command]` directly within your text.
-   **intelligent context**: automatically extracts surrounding text.
-   **smart routing**: infers the best response mode (socratic, contrarian, associate, etc.) using an llm (currently via the configured provider).
-   **templated prompts**: applies tailored prompts for different creative assistance modes.
-   **flexible display**: shows results as non-intrusive virtual text.
-   **multi-provider backend**: supports ollama, openai, anthropic, gemini, and openai-compatible apis (like openrouter).
-   **focus on human excellence**: no grammar correction or overwriting, only aids in exploring and deepening ideas, bringing out the best in your writing.
-   **syntax highlighting**: provides highlighting for `[!...]` blocks in `aidoc` filetypes.

## core interaction

1.  write your text, including a trigger like `[!explore this metaphor]`.
2.  place cursor on the trigger line **or visually select a block of text containing one or more triggers** and run `<leader>ai` in an `aidoc` file, or use the command `:AIPromptTrigger`.
    - if using visual selection, the selected text becomes the context, and **all** `[!...]` triggers found within the selection are processed sequentially.
    - otherwise, the trigger on the current line is used, along with surrounding context lines.
3.  the plugin sends the command and context to the configured ai provider to determine the response type (e.g., `interpret`) for **each trigger**.
4.  it then formats a detailed prompt using the appropriate template for that type.
5.  the final prompt is sent to the configured provider.
6.  the result is displayed as virtual text below the line or inserted into the buffer.
## example
below is an example of writing with various inline triggers in a document. italicized text is the ai-generated virtual text; i used gemma 3 12b for this example.
```markdown
i had the dream again last night.
the one with the corridor and the rainlight bleeding through the ceiling cracks.

it always starts the same way: footsteps behind me, slow, deliberate, like someone trying not to wake the dream.

[!what do the footsteps mean?]
*the footsteps likely represent an inescapable anxiety.*

*a pursuer–not necessarily malicious, but persistent.*
*it's the dread of something looming,*
*a consequence best avoided by continued,*
*though fearful, forward motion.*

i keep walking. not out of courage, but because stopping feels worse. [!why worse?]
*stopping–it isn't fear, precisely.*

*it's the taste of something already lost.*
*a hollowness the footsteps amplify.*

*perhaps the corridor \*is\* the escape.*
*and stillness…the inevitable reckoning.*

there's a door at the end of the hallway. it hums like it's alive. sometimes it's locked, sometimes it's not.

tonight, it wasn't.

[!generate 3 symbolic interpretations of the door]
*the door could be opportunity–*
*unlocked tonight, a rare, precarious chance.*

*or perhaps, a confrontation.*
*the humming, a warning of what lies beyond.*

*it might simply represent the unknown.*
*a necessary threshold, regardless of state.*

the room beyond was–

[!pause here. what tone shift would raise tension?]
*shift to a clipped, unsettlingly \*precise\* description.*

*maybe brief, almost clinical observation–*
*a focus on textures, smells, the room's geometry.*
```
## installation

**requires a configured and accessible ai provider backend.**

use your preferred plugin manager.

packer:
```lua
use {
  'cunuduh/naiad.nvim',
  requires = {
    'nvim-lua/plenary.nvim', -- required for http requests
  },
  config = function()
    require('naiad').setup({
      -- your configuration here (see below)
    })
  end
}
```

lazy.nvim:
```lua
{
  'cunuduh/naiad.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('naiad').setup({
      -- your configuration here (see below)
      provider = 'ollama', -- default, change as needed (e.g., 'openai', 'anthropic', 'gemini')
      model = 'gemma3:12b', -- specify your preferred model for the provider
      -- api_key = 'your_api_key_here', -- required for openai, anthropic, gemini
      -- base_url = 'http://localhost:11434', -- optional: override default url (for ollama, openai-compatible, etc.)
    })
  end,
}
```

## configuration

configure `naiad.nvim` in the `setup()` function. see `:help naiad-configuration` for all options.

```lua
require('naiad').setup({
  provider = 'openai', -- e.g., 'ollama', 'openai', 'anthropic', 'gemini'
  model = 'gpt-4.1', -- model name for the chosen provider
  api_key = os.getenv('OPENAI_API_KEY'), -- example: read from environment variable
  base_url = nil, -- optional: provider-specific defaults (http://localhost:11434 for ollama)
  context_lines_before = 10,
  context_lines_after = 5,
  request_timeout = 30000, -- in milliseconds
  max_tokens = 1024,
})
```

## usage

1.  ensure your chosen ai provider backend (e.g., `ollama serve`, or cloud service) is accessible.
2.  set the filetype of your markdown document to `aidoc` (`:set ft=aidoc`).
3.  write text and include triggers like `[!some command]`.
4.  on the trigger line, press `<leader>ai` (default mapping for `aidoc`), or use the command `:AIPromptTrigger`.
5.  view the virtual text result.
6.  use `<leader>ac` or `:AIClearVirtuals` to clear virtual text.

see `:help naiad` for detailed documentation.