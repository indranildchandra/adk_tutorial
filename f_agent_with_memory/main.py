import asyncio
import os
from pathlib import Path

from google.adk.runners import Runner
from google.adk.sessions import DatabaseSessionService
from google.genai.types import Content, Part
from agents import root_agent

# --- Configuration ---
SESSIONS_DIR = Path(os.path.expanduser("~")) / ".adk" / "sessions"
os.makedirs(SESSIONS_DIR, exist_ok=True)
DB_FILE = SESSIONS_DIR / "adk_cli_sessions.db"
SESSION_URL = f"sqlite:///{DB_FILE}"
MY_USER_ID = "local_cli_user_001"
MY_SESSION_ID = f"{MY_USER_ID}_cli_session"


async def main():
    print("Initializing Personalized Trip Planner CLI...")
    print(f"Session database: {DB_FILE}")
    print("--------------------------------------------------")

    session_service = DatabaseSessionService(db_url=SESSION_URL)
    session = await session_service.get_session(
        app_name=root_agent.name, user_id=MY_USER_ID, session_id=MY_SESSION_ID
    )
    if session is None:
        print(f"No existing session found. Creating a new one: {MY_SESSION_ID}")
        session = await session_service.create_session(
            app_name=root_agent.name, user_id=MY_USER_ID, session_id=MY_SESSION_ID
        )
    print(f"Session '{session.id}' is ready for user '{session.user_id}'.")

    runner = Runner(
        agent=root_agent,
        session_service=session_service,
        app_name=root_agent.name
    )

    while True:
        try:
            query = input("You: ")
            if query.lower() in ["quit", "exit"]:
                print("Goodbye!")
                break

            print("Agent: ", end="", flush=True)

            async for event in runner.run_async(
                user_id=session.user_id,
                session_id=session.id,
                new_message=Content(parts=[Part(text=query)], role="user")
            ):
                if not event.content:
                    continue

                for part in event.content.parts:
                    if hasattr(part, "text") and part.text:
                        print(part.text, end="", flush=True)
                    elif event.author == "user" and hasattr(part, "function_response"):
                        tool_name = part.function_response.name
                        tool_result = part.function_response.response
                        print(f"\n\n[DEBUG] Tool '{tool_name}' returned: {tool_result}\n")
                        print("Agent: ", end="", flush=True)

            print("\n")

        except (KeyboardInterrupt, EOFError):
            print("\nGoodbye!")
            break

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nShutting down.")
