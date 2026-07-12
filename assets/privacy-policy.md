# Privacy Policy – Any AI for Notion

**Last Updated:** July 12, 2026

## 1. Introduction

Any AI for Notion is an open-source application that lets you interact with your Notion workspace through any AI provider of your choice. This Privacy Policy explains exactly what data we collect and how we handle it.

**The short version:** We collect nearly nothing — just one anonymous usage ping via a `/track` API. That's it.

## 2. What We Collect

Any AI for Notion implements **one single analytics mechanism**: a `/track` API hosted on **Google Cloud Run**.

### 2.1 What the `/track` API collects:

- A basic event type (e.g., `app_launch`, `install`)
- An anonymous device-generated identifier (non-personal, non-accountable)
- The platform you are running on (iOS, Android, macOS, Windows, Linux)
- The app version and build number

### 2.2 What it does NOT collect:

- No name, email, or any personal identifiable information
- No IP address logging
- No Notion workspace data or content
- No AI prompts, responses, or conversation history
- No API keys or credentials
- No file system or local files
- No browser history, cookies, or local storage inspection
- No location data
- No device hardware or OS version details

### 2.3 Why we collect this

This data is used exclusively for anonymous usage analytics — understanding how many people are using the app, how often, and from which channels. This helps us:

- Measure app store performance
- Prioritize product improvements
- Ensure the app is functioning as expected

## 3. What We Do NOT Collect (At All)

Beyond the single `/track` ping described above, **we collect nothing else**:

- No telemetry
- No crash reports
- No analytics beyond the `/track` API
- No cookies
- No tracking pixels or embedded scripts
- No server-side logging that persists personal data

## 4. Your Data Stays With You

### 4.1 API Keys

Your AI provider API keys (OpenAI, Anthropic, Google, etc.) and your Notion integration token are stored **locally on your device**. They are never sent to us, never uploaded anywhere, and never shared with anyone unless you choose to share them.

### 4.2 Notion Content

Your Notion workspace data is accessed through the Notion API. We never see, store, or process your Notion content.

### 4.3 AI Prompts & Responses

When you send a message in the chat, the app transmits the following data to the AI provider endpoint you have configured:

- Your typed messages and full conversation history
- Your system prompt
- The content of your persistent memory file (injected into every request)
- Notion page content, retrieved via Notion tool calls when the assistant requests it
- Content fetched from web pages via the built-in fetch_url tool
- Tool call schemas describing the available Notion and built-in tools

**How it is transmitted:** Data is sent via HTTPS POST to the `/chat/completions` endpoint URL you entered in Settings, authenticated with your API key as a Bearer token.

**Who it is sent to:** The AI provider you have chosen and configured (e.g. OpenAI, OpenRouter, Azure OpenAI, or a self-hosted server like Ollama or LM Studio). The app does not route data through any intermediary server. Communication goes directly from your device to your configured endpoint.

**Purpose:** To generate chat responses and execute tool calls (reading/writing Notion pages, setting reminders, searching memory, fetching web content).

**Third-party protection:** Your AI provider's privacy policy governs how they handle the data they receive. We have no control over how third-party AI providers process, store, or retain your data. We encourage you to review your provider's privacy policy.

**Local LLM mode:** When using a local server (Ollama, LM Studio, etc.), data stays on your machine and is never sent to the internet.

### 4.4 Configuration & Preferences

All app settings, preferences, and configurations are stored **locally on your device**.

## 5. Local LLM Usage (Maximum Privacy)

When using local language models via Ollama, LM Studio, or similar providers:

- Everything runs **entirely on your machine**
- **No AI data** leaves your computer
- The only outbound request is the anonymous `/track` ping
- No internet connection required for AI processing

This is the most private mode of operation.

## 6. Data Storage & Retention

The `/track` API receives fully anonymous event pings with no personal data. Since the data is anonymous and non-personal, no specific retention period is defined.

There is **no persistent database** of user information anywhere in the system.

## 7. Data Sharing

**We do not share, sell, or trade any data.**

- The `/track` data is used internally for product analytics only
- It is **not** shared with third parties
- It is **not** used for advertising
- It is **not** sold to data brokers

## 8. Third-Party Services

### 8.1 Notion

When you connect to Notion, communications are handled through the Notion API. Your use of Notion is subject to [Notion's Privacy Policy](https://www.notion.so/privacy).

### 8.2 AI Providers

When you use an AI provider (OpenAI, OpenRouter, Anthropic, Google, or a self-hosted server), the app sends your messages, conversation history, system prompt, persistent memory content, Notion page content (via tool call results), and fetched web page content to the provider's endpoint. This data is transmitted directly from your device to the endpoint URL you configured, via HTTPS, using your API key for authentication. Your use of the AI provider is subject to that provider's privacy policy. We encourage you to review their policies:

- [OpenAI Privacy Policy](https://openai.com/privacy/)
- [OpenRouter Privacy Policy](https://openrouter.ai/privacy)
- [Anthropic Privacy Policy](https://www.anthropic.com/privacy)
- [Google Privacy Policy](https://policies.google.com/privacy)
- [Ollama Privacy](https://ollama.ai/privacy)

**We have no control over how these third parties handle your data.**

### 8.3 Google Cloud Run

The `/track` API is hosted on Google Cloud Run. Data processing is subject to [Google's Privacy Policy](https://policies.google.com/privacy) and [Cloud Run's data processing terms](https://cloud.google.com/terms/data-processing-terms). Only anonymous, non-personal data is involved.

## 9. Children's Privacy

Any AI for Notion is not directed at children under the age of 13. The minimal data collected via the `/track` API does not include any information that could identify a child, and we do not knowingly collect personal information from children.

## 10. Data Security

- The `/track` API endpoint accepts anonymous, non-personal data only — there is nothing sensitive to compromise
- API keys and configuration remain **local to your device** — their security is determined by your device's own security measures
- No authentication tokens, session data, or user accounts are involved

## 11. Your Rights

Since we collect only anonymous, non-personal data:

- **Right to Access** – The `/track` data is anonymous aggregated counts with no link to any individual
- **Right to Deletion** – Anonymous data cannot be attributed to or deleted for a specific individual. If you uninstall the app, no further pings will be sent
- **Right to Rectification** – There is no personal data to correct
- **Right to Data Portability** – The `/track` data is anonymous and non-personal

## 12. International Transfers

The `/track` API is hosted on Google Cloud Run, which may process data across Google Cloud's global infrastructure. No personal data is involved in this transfer — only anonymous event pings.

## 13. Opting Out

If you prefer to block the `/track` ping entirely, you may:

- Block the endpoint at the network level (e.g., firewall or ad-blocker rules)
- Use a modified build of this open-source application with the analytics call removed

## 14. Changes to This Policy

We may update this Privacy Policy from time to time. If we do, we will update the "Last Updated" date at the top. Since the data collected is minimal and anonymous, changes are likely to be rare.

## 15. Contact

If you have any questions about this Privacy Policy, please reach out through our official project channels or open an issue on the GitHub repository.

---

_This product uses the Notion API. "Notion" is a trademark of Notion Labs Inc. All AI provider names are trademarks of their respective owners._
