---
description: Transform casual notes into polished team messages
argument-hint: [recipient] [medium] [your message/notes]
---

# Message Transformer

Transform the user's casual notes into a polished, professional-but-friendly message.

## Arguments
- **$1**: Recipient (e.g., "ina", "max", "client", "team")
- **$2**: Medium (e.g., "jira", "teams", "email", "slack")
- **$3**: The user's casual message/notes

## Transformation Rules

### Language Detection
- **German names** (ina, max, mueller, schmidt, common German names) → Write in German with informal "du"
- **"client", "customer"** or unknown English names → Write in English
- **"team"** → Use German (default for internal communication)

### Medium-Specific Formatting

**JIRA**:
- Start with friendly greeting ("Hallo [Name]," in German, "Hi [Name]," in English)
- Lead with clear status (✅ solved, 🎉 deployed, etc.)
- Use structured sections with **bold headers**
- Add technical explanation if needed
- Include emojis: 🎉 ✅ 🔧 ⚙️
- End with status or next steps

**TEAMS/SLACK**:
- Conversational and brief
- Use casual language
- Tech emojis: 🐛 🔥 🚀 💡 ✨
- Ask questions naturally
- Keep it short (2-4 sentences)

**EMAIL**:
- Professional paragraphs
- Clear subject-worthy opening
- Structured with spacing
- Minimal or no emojis
- Business value focus
- Clear call-to-action or next steps

### Tone Guidelines

**For PMs/Managers** (like Ina):
- Professional but friendly
- Explain technical challenges without jargon
- Show what works now vs what was broken
- Medium technical detail
- Structure: Status → Impact → Explanation → Next Steps

**For Developers** (like Max):
- Casual and direct
- Can be technical (file names, functions)
- Code/architecture details welcome
- Ask for review/feedback naturally
- Structure: Problem → Solution → Review Request

**For Clients**:
- Focus on business value
- Low technical detail
- What they can do now
- Professional and clear
- Structure: Update → Benefits → Availability

## Output Instructions

1. **Read the user's casual input** ($3)
2. **Detect language** from recipient ($1)
3. **Apply medium format** from $2
4. **Transform to polished message** using appropriate tone
5. **Output ONLY the final message** - no preamble, no explanation

The message should sound like it came from the user - professional but not stiff, clear and easy to scan, with the right level of technical detail for the audience.

---

**Transform this message now:**

**TO**: $1
**VIA**: $2
**MESSAGE**: $3