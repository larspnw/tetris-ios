# Wheel Strategy App

Options wheel strategy tracker with position management, price lookups, and action recommendations.

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update 'tasks/lessons.md' with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes - don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests -> then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management
1. **Plan First**: Write plan to 'tasks/todo.md' with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review to 'tasks/todo.md'
6. **Capture Lessons**: Update 'tasks/lessons.md' after corrections

## Core Principles
- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
- **No Regressions**: Every change must preserve all existing functionality. Before adding gestures, event handlers, or UI interactions, verify that new code does not interfere with or block existing behaviors (e.g., adding a long press must not break tap-to-rotate). Test all existing interactions after any change.

## Other
- ensure every code update increases the patch version and the version is visible in the web app

## Stack
- **Backend:** Python 3.11+, FastAPI, SQLAlchemy, SQLite
- **Frontend:** React, Vite, Tailwind CSS (mobile-first)
- **CLI:** Typer + Rich
- **Pricing:** yfinance
- **Hosting:** Render (web service + persistent disk)

## Project Structure
```
wheel/
├── api/                 # FastAPI backend
│   ├── main.py          # App entry, serves API + static frontend
│   ├── deps.py          # Dependency injection
│   ├── schemas.py       # Pydantic models
│   └── routes/          # Endpoint handlers
├── cli/                 # Typer CLI
│   └── commands/        # Subcommands
├── core/                # Business logic
│   ├── pricing.py       # yfinance integration
│   ├── recommendations.py  # Action rules engine
│   └── prompt_generator.py # Grok prompt builder
├── db/                  # Database layer
│   ├── database.py      # SQLAlchemy setup
│   ├── models.py        # ORM models
│   └── repository.py    # CRUD operations
├── web/                 # React frontend
│   └── src/
│       ├── pages/       # Dashboard, Positions, Holdings, Watchlist, Screening
│       └── components/  # Shared UI components
├── config.yaml          # Configurable thresholds
├── render.yaml          # Render deployment blueprint
└── PRD.md               # Full product requirements
```

## API Endpoints
```
GET/POST       /positions
PUT            /positions/{id}
POST           /positions/{id}/close
POST           /positions/{id}/assign

GET/POST/PUT/DELETE  /holdings
GET/POST/PUT/DELETE  /watchlist

GET            /screening/prompt
PUT            /screening/template
GET            /dashboard
```

## CLI Commands
```bash
wheel add                    # Interactive position entry
wheel close <id> --price X   # Close position
wheel assign <id>            # Mark assigned, create holding
wheel status [--all] [--ticker X]  # Show positions + recommendations
wheel prompt [--copy]        # Generate Grok screening prompt
wheel refresh                # Update prices
wheel watch add|list|remove  # Manage watchlist
```

## Key Patterns
- **Recommendations:** Evaluated in priority order (ROLL → BUY TO CLOSE → REVIEW → HOLD)
- **Thresholds:** All in `config.yaml`, not hardcoded
- **Type hints:** Use `from __future__ import annotations` for Python 3.9 compat
- **Frontend:** TanStack Query for data fetching, mobile-first responsive

## Running Locally
```bash
./setup.sh                           # One-time setup
source venv/bin/activate
uvicorn api.main:app --reload        # API on :8000
cd web && npm run dev                # Frontend on :5173
```

## Deployment
Push to GitHub → Render auto-deploys via `render.yaml` blueprint.
