# Notion Any AI

Open-source Flutter app that connects an OpenAI-compatible chat model to your Notion workspace via the [Model Context Protocol](https://modelcontextprotocol.io) (MCP). Chat with an assistant that can read and write your Notion pages, set reminders, remember things across conversations, and fetch web content, all on-device with OAuth-based Notion access.

Cross-platform: Android, iOS, macOS, Windows, Linux.

![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-blue)
![License](https://img.shields.io/badge/license-GPL--3.0-green)
![Flutter](https://img.shields.io/badge/Flutter-3.44.4-02569B)

## Features

- **Streamed chat** with an OpenAI-compatible endpoint (any server implementing the OpenAI Chat Completions API with tool calls).
- **Notion MCP tool calls**. The assistant can call Notion tools exposed by `mcp.notion.com` to search pages, read content, and create or update pages. Notion connection uses OAuth 2.0 with [RFC 7591 dynamic client registration](https://datatracker.ietf.org/doc/html/rfc7591), so no client ID or secret is baked into the app.
- **Built-in tools**, always available alongside Notion tools:
  - `get_current_datetime` - current date/time in the local timezone.
  - `schedule_reminder`, `list_reminders`, `cancel_reminder` - local push notifications that fire on-device. Reminders persist across app restarts on iOS, Android, macOS, and Windows (Linux fires only while the app runs).
  - `read_memory`, `search_memory`, `add_memory`, `delete_memory` - a shared `memory.md` the assistant can read and write to carry facts across conversations.
  - `fetch_url` - fetch a web page and return it as readable plain text.
- **Voice input** with on-device recording and speech-to-text transcription sent to the configured endpoint.
- **Conversation history** stored locally as JSON. Each conversation is a file you can reveal in your file manager.
- **System prompt** configurable in settings.
- **Notion page picker** with search, breadcrumbs, recent pages, and selected-page persistence.
- **Notion design system** throughout. Light and dark themes, warm off-white canvas, serif display fonts, restrained accent blue. See [DESIGN.md](DESIGN.md) for the full system.

## Requirements

- Flutter 3.44.4 (managed via [FVM](https://fvm.app))
- Dart SDK ^3.12.2
- An OpenAI-compatible chat completion endpoint (OpenAI, Azure OpenAI, a local server, etc.) that supports tool/function calls and streaming
- A Notion account (the app connects to your workspace via OAuth on first use)

## Getting started

Clone and install dependencies:

```bash
git clone https://github.com/<your-user>/notion-any-ai.git
cd notion-any-ai
fvm install
fvm flutter pub get
```

Run on your preferred device:

```bash
fvm flutter run                 # default device
fvm flutter run -d macos        # macOS
fvm flutter run -d chrome       # web (desktop-only OAuth flow)
```

### First-run setup

1. Open the app. You land on the chat screen.
2. Open settings and configure your **AI provider**: the chat completion endpoint URL and model name (for example `https://api.openai.com/v1/chat/completions` and `gpt-4o`).
3. Connect Notion: tap **Connect Notion** and authorize the app in the browser. On desktop the app runs a temporary local loopback server to receive the OAuth callback. On mobile it uses an in-app browser and a custom URL scheme (`notionopenai://oauth/callback`).
4. Optionally configure a **system prompt**, enable **built-in tools**, and set up **voice input** transcription.
5. Start chatting. The assistant can now call Notion tools and built-in tools.

No API keys, Notion client IDs, or secrets are needed at build time. The AI provider endpoint is the only thing you must configure in-app. Notion credentials are obtained at runtime via OAuth and stored in platform secure storage.

## Platform notes

| platform | OAuth flow                                | reminders           | notes                                                |
| -------- | ----------------------------------------- | ------------------- | ---------------------------------------------------- |
| Android  | in-app browser + `notionopenai://` scheme | persistent          | microphone permission requested on first voice input |
| iOS      | in-app browser + `notionopenai://` scheme | persistent          | microphone permission requested on first voice input |
| macOS    | local loopback HTTP server                | persistent          | entitlements include keychain and network            |
| Windows  | local loopback HTTP server                | persistent          | firewall may prompt on first OAuth                   |
| Linux    | local loopback HTTP server                | only while app runs | Snap package uses strict confinement                 |

## Project structure

The app follows a feature-based structure under `lib/`:

```
lib/
  app/            # theme, shared widgets, storage providers
  features/
    ai_provider/      # OpenAI-compatible endpoint config
    builtin_tools/    # registry of local tools (datetime, reminders, memory, fetch)
    chat/             # chat screen, message list, bubbles, OpenAI client, MCP bridge
    conversations/    # local conversation history (JSON files)
    memory/           # shared memory.md read/write UI and storage
    notifications/    # local push reminders
    notion/           # OAuth, MCP client, page search, page picker, tool list
    settings/         # settings screen
    system_prompt/    # configurable system prompt
    voice_input/      # recording and transcription
  main.dart
```

## Build

Release builds per platform:

```bash
fvm flutter build apk --release
fvm flutter build ipa --release
fvm flutter build macos --release
fvm flutter build windows --release
fvm flutter build linux --release
```

App icons and splash are generated with `icons_launcher` and `flutter_native_splash`:

```bash
fvm dart run icons_launcher:create
fvm dart run flutter_native_splash:create
```

## License

Copyright (C) 2026 Matteo Ricupero

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the [LICENSE](LICENSE) file for the full text, or <https://www.gnu.org/licenses/>.
