# UI Benchmark Notes

This redesign moves the app away from a generic chat panel and toward a visual-novel interview scene.

References checked:

- Coffee Talk: a conversation-first game built around listening to people, using a character/scene-centered presentation and calm palette.
  - https://www.coffeetalk.info/
- VA-11 Hall-A: a dialogue-heavy interface where repeated small choices keep the player in a conversational rhythm.
  - https://store.steampowered.com/app/447530/VA11_HallA_Cyberpunk_Bartender_Action/
- Her Story: interview fragments and evidence-driven discovery as the core interaction.
  - https://www.herstorygame.com/
- USC Shoah Foundation Dimensions in Testimony: visitors ask direct questions and receive testimony-shaped answers.
  - https://sfi.usc.edu/dit
- Kind Words: short, low-pressure, emotionally restrained text exchange.
  - https://www.popcannibal.com/kindwords/
- Gone Home: ordinary objects in a room reveal a person's life without exposition first.
  - https://gonehome.com/
- A Normal Lost Phone: personal clues gradually build an understanding of someone else's life.
  - https://store.steampowered.com/app/523210/A_Normal_Lost_Phone/
- Before Your Eyes: intimate life-story pacing that avoids system-heavy explanation.
  - https://www.beforeyoureyesgame.com/
- Visual Novel Machinery dialog UI setup: dialog text, character name, and choice buttons are separate UI widgets.
  - https://visualnovelmachinery.com/docs/project-setup/setup-dialog-box-ui/
- Eliza: an AI-counseling visual novel reference for an AI-mediated conversation premise.
  - https://steamdb.info/app/716500/screenshots/
- Agentic chat interface patterns: avoid purely linear text-only chat; expose the agent's lead and keep topic flow visible.
  - https://agentic-design.ai/patterns/ui-ux-patterns/chat-interface-patterns/

Applied decisions:

- Use a full 1920x1080 illustrated study-room scene rather than a plain white stage.
- Use a fictional Korean male computer-science graduate student character, seated across a desk.
- Avoid visible disability aids in the character art so the first visual read is not the disability.
- Put the main answer in a large bottom dialogue box, with a speaker name plate.
- Keep the right rail as a conversation-flow panel with AI-led suggested questions, not a generic empty chat column.
- Keep chat history secondary and compact.
- Start with an AI-led opening prompt instead of waiting for the user to ask first.
