# cobold-cli

<p align="center">
  <img src="assets/Kobold.png" alt="cobold mascot" width="160"/>
</p>

> An AI chat agent written entirely in **COBOL** — because why not.

`cobold-cli` is a terminal chatbot that talks to a large language model via the [OpenRouter](https://openrouter.ai) API. It maintains full conversation history, supports tool calls (the agent loop), and can fetch live weather data — all implemented in plain COBOL 85 without any third-party libraries.

Built as a submission for the **[ai_devs4](https://aidevs.pl)** course.

---

## Screenshot

![cobold-cli session showing a weather query](assets/sample.png)

---

## How it works

```
┌──────────────┐    user input     ┌─────────────────┐    HTTP/curl    ┌──────────────────┐
│   main.cob   │ ───────────────▶  │  context-mgr    │                │  OpenRouter API  │
│  (REPL loop) │                   │  (message store) │                │  (any LLM model) │
└──────────────┘                   └─────────────────┘                └──────────────────┘
        │                                   ▲                                  │
        │                                   │ append reply                     │
        ▼                                   │                                  ▼
  ┌─────────────┐   tool_calls?   ┌──────────────────┐   get_weather   ┌─────────────────┐
  │  ai-caller  │ ──────────────▶ │  weather-tool    │ ─────────────▶  │   wttr.in API   │
  │ (HTTP layer) │ ◀─────────────  │  (tool executor) │ ◀─────────────  └─────────────────┘
  └─────────────┘   tool result   └──────────────────┘
```

### Modules

| File | Program ID | Responsibility |
|---|---|---|
| [src/main.cob](src/main.cob) | `COBOLD-CLI` | REPL loop, startup banner, context size display |
| [src/context-mgr.cob](src/context-mgr.cob) | `CONTEXT-MGR` | Builds and grows the JSON `messages` array across turns |
| [src/ai-caller.cob](src/ai-caller.cob) | `AI-CALLER` | Serialises the payload, calls `curl`, parses the JSON response, runs the tool-call agent loop |
| [src/weather-tool.cob](src/weather-tool.cob) | `WEATHER-TOOL` | Fetches current weather from `wttr.in` and returns a plain-text summary |
| [src/env-reader.cob](src/env-reader.cob) | `ENV-READER` | Reads `OPENROUTER_API_KEY` and `OPENROUTER_MODEL` from the `.env` file next to the binary |
| [src/prompt-loader.cob](src/prompt-loader.cob) | `PROMPT-LOADER` | Loads `prompts/system-prompt.txt` and injects it as the first system message |

### Agent loop

When the model responds with a `tool_calls` block instead of plain text, `AI-CALLER` detects it, extracts the function name and arguments from the raw JSON using character-by-character scanning, executes the matching COBOL tool program, appends both the assistant tool-call message and the tool result to the context, and re-sends the whole conversation to the API — repeating until the model returns a regular text reply.

### JSON handling

There is no JSON library. The context buffer (`PIC X(60000)`) is a raw JSON string grown by direct `STRING … INTO … WITH POINTER` statements. Escaping and unescaping of `"`, `\`, `\n`, `\t`, and `\r` is done one character at a time in `CONTEXT-MGR` and `AI-CALLER`.

---

## Requirements

| Dependency | Purpose |
|---|---|
| [GnuCOBOL](https://gnucobol.sourceforge.io) (`cobc`) | Compiles all `.cob` sources into a single native binary |
| `curl` | HTTP calls to OpenRouter and wttr.in |
| An [OpenRouter](https://openrouter.ai) API key | Gives access to any supported LLM |

---

## Setup

```bash
# 1. Clone
git clone <repo-url>
cd cobold-cli

# 2. Configure
cp .env.example .env
# Edit .env — set your API key and the model you want, e.g.:
#   OPENROUTER_API_KEY=sk-or-...
#   OPENROUTER_MODEL=openai/gpt-4o-mini

# 3. Build
make

# 4. Run
./dist/cobold
```

Type your message and press Enter. Type `/q` to quit.

The binary looks for `.env` and `prompts/system-prompt.txt` relative to its own location, so the `dist/` directory is self-contained.

---

## Configuration

**`.env`** (next to the binary):
```
OPENROUTER_API_KEY=sk-or-...
OPENROUTER_MODEL=openai/gpt-4o-mini
```

**`prompts/system-prompt.txt`** — the system prompt loaded at startup. Edit it to change the assistant's persona or instructions.

---

## Context window

The conversation buffer is 60 000 characters. The footer line `context @> XXXXX/60000 chars used` shows how much is consumed after each turn. When the buffer fills up the oldest messages are silently overwritten (COBOL `STRING … WITH POINTER` simply stops writing).

---

## Credits

Logo based on artwork by **Christopher Burdett** for *Wizards of the Coast* — [christopherburdett.com](http://christopherburdett.com)
