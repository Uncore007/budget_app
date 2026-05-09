# Budget App

## Goal
A simple personal budgeting app modelled after a spreadsheet that tracks
monthly income, expenses, and savings allocations. The aim is simplicity —
no unnecessary complexity, no JavaScript frameworks.

## Tech Stack
- **Ruby** with **Sinatra** — lightweight web framework, single app.rb file
- **Sequel** with **SQLite** — database ORM, migrations in /migrations
- **HTMX** — inline add/delete without page reloads, no custom JS
- **Bootstrap 5** — layout and styling via CDN, no build step
- **ERB** — templating, partials rendered with erb :partial_name

## Project Structure
app.rb              # All routes
db.rb               # Not used — DB connection is in app.rb
migrate.rb          # Run with: bundle exec ruby migrate.rb
seed.rb             # Seeds default expense categories
migrations/         # Sequel migrations
views/
layout.erb        # Bootstrap shell, loads HTMX via CDN
index.erb         # Main page, two-column layout
income.erb        # Income table + add form
income_row.erb    # Single income row partial (returned by POST /income)
expenses.erb      # Expenses grouped by category
expense_row.erb   # Single expense row partial
savings.erb       # Savings allocations table + add form
savings_row.erb   # Single savings row partial
summary.erb       # Summary card, loaded via hx-get="/summary"

## Data Model
- **income_sources** — name, amount (gross), tax_rate (e.g. 0.3)
- **expense_categories** — name (Household, Living, Personal, etc.)
- **expense_items** — name, amount, expense_category_id
- **savings_allocations** — name, rate (e.g. 0.25 = 25%)
- **settings** — key/value table for things like tithe rate

## Key Conventions
- Routes follow REST: GET /income, POST /income, DELETE /income/:id
- HTMX partials return layout: false — just the HTML fragment
- Summary auto-refreshes via hx-trigger="load, htmx:afterRequest from:body"
- Savings amounts are calculated (not stored) — rate * savings_pool
- savings_pool = total net income - total expenses
- Net income = gross * (1 - tax_rate)

## Running the App
```bash
bundle exec ruby migrate.rb   # set up database
bundle exec ruby seed.rb      # seed expense categories
bundle exec ruby app.rb       # start server at http://localhost:4567
```
