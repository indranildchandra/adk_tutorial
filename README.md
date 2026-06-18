# ADK Tutorial - Day Trip Planning Agents

A hands-on tutorial for Google's AI Development Kit (ADK) demonstrating progressively advanced agent patterns: single agents, sequential workflows, parallel execution, loop agents, custom agents, routing, agent-as-tool, memory, and MCP tool integration.

## Modules

| Module | Pattern |
|--------|---------|
| `a_single_agent` | Basic single agent with Google Search |
| `b1_sequential_agent` | SequentialAgent pipeline |
| `b2_parallel_agent` | ParallelAgent (simultaneous specialists) |
| `b3_loop_agent` | LoopAgent with iterative refinement |
| `b4_manual_sequential_flow` | Manual routing with multiple agents |
| `c_custom_agent` | Custom BaseAgent with Python decision logic |
| `d_routing_agent` | Router agent with sub-agent delegation |
| `e_agent_as_tool` | Agents wrapped as tools (AgentTool) |
| `f_agent_with_memory` | Session-based persistent memory |
| `g_agents_mcp` | MCP Toolbox integration with SQLite |

## Prerequisites

- Python 3.9 or higher
- One of the two authentication options below

### Authentication Options

| | Option 1 (Default) | Option 2 |
|-|-------------------|----------|
| **Method** | Vertex AI | Gemini API Key |
| **Requires** | Google Cloud project | Nothing — just an API key |
| **Cost** | GCP billing (free tier available) | Free tier available |
| **Setup** | `gcloud auth application-default login` | Get key at [aistudio.google.com/apikey](https://aistudio.google.com/apikey) |

The setup script will ask which option you want during configuration.

## Quick Setup

### Mac / Linux

```bash
chmod +x setup_venv.sh

# Default — Vertex AI (requires a Google Cloud project)
./setup_venv.sh

# Alternative — Gemini API key (free, no Google Cloud needed)
./setup_venv.sh --use-gemini-api-key
```

The script will:
1. Check your Python version (3.9+ required)
2. Create a `.adk_env` virtual environment
3. Install all dependencies from `requirements.txt`
4. Prompt for your credentials and create a `.env` file
5. Set up the SQLite database for module `g_agents_mcp`

### Manual Setup

```bash
python3 -m venv .adk_env
source .adk_env/bin/activate      # Windows: .adk_env\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env — enable Option 1 (Vertex AI) or Option 2 (Gemini API key), see comments inside
python3 setup_trip_database.py
```

## Running the Agents

Activate the virtual environment first:

```bash
source .adk_env/bin/activate
```

### ADK Web UI (modules a through g, except g_agents_mcp)

Use `run.sh` from the repo root. It starts `adk web` with persistent session storage so sessions survive page refreshes:

```bash
chmod +x run.sh
./run.sh
```

Open [http://localhost:8080](http://localhost:8080) and select any module from the dropdown.

### CLI — module f (persistent memory)

Module `f_agent_with_memory` has a CLI runner that demonstrates persistent memory across multiple turns using a SQLite-backed session:

```bash
cd f_agent_with_memory
python main.py
```

Sessions are stored at `~/.adk/sessions/adk_cli_sessions.db` and persist between runs.

### CLI — module g (MCP Toolbox)

Module `g_agents_mcp` requires a running MCP Toolbox server. Start it in a separate terminal before running the agent:

```bash
# Terminal 1 - start the MCP Toolbox server
# See: https://github.com/googleapis/genai-toolbox
toolbox --tools-file mcp_tool_box/trip_tools.yaml

# Terminal 2 - run the agent
cd g_agents_mcp
python main.py
```

The `destinations.db` database is created automatically by the setup script. If you need to recreate it:

```bash
python setup_trip_database.py
```

## Environment Variables

**Option 1 — Vertex AI (default):**

| Variable | Description |
|----------|-------------|
| `GOOGLE_GENAI_USE_VERTEXAI` | Set to `TRUE` |
| `GOOGLE_CLOUD_PROJECT` | Your GCP project ID |
| `GOOGLE_CLOUD_LOCATION` | GCP region (default: `us-central1`) |

**Option 2 — Gemini API key:**

| Variable | Description |
|----------|-------------|
| `GOOGLE_GENAI_USE_VERTEXAI` | Set to `FALSE` |
| `GOOGLE_API_KEY` | Your Gemini API key from AI Studio |

**Module g only:**

| Variable | Description |
|----------|-------------|
| `MCP_SERVER_URL` | MCP server URL (default: `http://127.0.0.1:7001`) |

See `.env.example` for a ready-to-copy template with both options.

## Deactivating

```bash
deactivate
```
