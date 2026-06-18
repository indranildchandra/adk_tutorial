import asyncio
import re

from google.adk.agents import Agent
from google.adk.sessions import Session, InMemorySessionService
from google.adk.runners import Runner
from google.genai.types import Content, Part
from agent import foodie_agent, weekend_guide_agent, transportation_agent, router_agent, worker_agents


async def run_agent_query(agent: Agent, query: str, session: Session, user_id: str, is_router: bool = False):
    """Initializes a runner and executes a query for a given agent and session."""
    print(f"\nRunning query for agent: '{agent.name}' in session: '{session.id}'...")

    runner = Runner(
        agent=agent,
        session_service=session_service,
        app_name=agent.name
    )

    final_response = ""
    try:
        async for event in runner.run_async(
            user_id=user_id,
            session_id=session.id,
            new_message=Content(parts=[Part(text=query)], role="user")
        ):
            if not is_router:
                print(f"EVENT: {event}")
            if event.is_final_response():
                final_response = event.content.parts[0].text
    except Exception as e:
        final_response = f"An error occurred: {e}"

    if not is_router:
        print("\n" + "-"*50)
        print("Final Response:")
        print(final_response)
        print("-"*50 + "\n")

    return final_response

session_service = InMemorySessionService()
my_user_id = "adk_adventurer_001"


async def run_sequential_app():
    queries = [
        "I want to eat the best sushi in Palo Alto.",
        "Are there any cool outdoor concerts this weekend?",
        "Find me the best sushi in Palo Alto and then tell me how to get there from the Caltrain station."
    ]

    for query in queries:
        print(f"\n{'='*60}\nProcessing New Query: '{query}'\n{'='*60}")

        router_session = await session_service.create_session(app_name=router_agent.name, user_id=my_user_id)
        print("Asking the router agent to make a decision...")
        chosen_route = await run_agent_query(router_agent, query, router_session, my_user_id, is_router=True)
        chosen_route = chosen_route.strip().replace("'", "")
        print(f"Router has selected route: '{chosen_route}'")

        if chosen_route == 'find_and_navigate_combo':
            print("\n--- Starting Find and Navigate Combo Workflow ---")

            foodie_session = await session_service.create_session(app_name=foodie_agent.name, user_id=my_user_id)
            foodie_response = await run_agent_query(foodie_agent, query, foodie_session, my_user_id)

            match = re.search(r"\*\*(.*?)\*\*", foodie_response)
            if not match:
                print("Could not determine the restaurant name from the response.")
                continue
            destination = match.group(1)
            print(f"Extracted Destination: {destination}")

            directions_query = f"Give me directions to {destination} from the Palo Alto Caltrain station."
            print(f"\nNew Query for Transport Agent: '{directions_query}'")
            transport_session = await session_service.create_session(app_name=transportation_agent.name, user_id=my_user_id)
            await run_agent_query(transportation_agent, directions_query, transport_session, my_user_id)

            print("--- Combo Workflow Complete ---")

        elif chosen_route in worker_agents:
            worker_agent = worker_agents[chosen_route]
            worker_session = await session_service.create_session(app_name=worker_agent.name, user_id=my_user_id)
            await run_agent_query(worker_agent, query, worker_session, my_user_id)
        else:
            print(f"Error: Router chose an unknown route: '{chosen_route}'")

if __name__ == "__main__":
    asyncio.run(run_sequential_app())
