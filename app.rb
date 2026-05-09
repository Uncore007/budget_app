require "sinatra"
require "sinatra/reloader" if development?
require "sequel"

DB = Sequel.connect("sqlite://budget.db")

helpers do
  def calculate_totals
    income_sources = DB[:income_sources].all
    expense_items  = DB[:expense_items].all

    total_income   = income_sources.sum { |s| s[:amount] * (1 - s[:tax_rate]) }
    total_expenses = expense_items.sum  { |i| i[:amount] }
    savings_pool   = total_income - total_expenses

    [total_income, total_expenses, savings_pool]
  end
end

get "/" do
  @income_sources      = DB[:income_sources].all
  @categories          = DB[:expense_categories].all
  @expense_items       = DB[:expense_items].all
  @savings_allocations = DB[:savings_allocations].all
  @total_income, @total_expenses, @savings_pool = calculate_totals
  erb :index
end

# Income routes
get "/income" do
  @income_sources = DB[:income_sources].all
  erb :income, layout: false
end

post "/income" do
  DB[:income_sources].insert(
    name:     params[:name],
    amount:   params[:amount].to_f,
    tax_rate: params[:tax_rate].to_f
  )
  source = DB[:income_sources].order(:id).last
  erb :income_row, layout: false, locals: { source: source }
end

delete "/income/:id" do
  DB[:income_sources].where(id: params[:id].to_i).delete
  ""
end

# Expense routes
post "/expenses" do
  DB[:expense_items].insert(
    name:                params[:name],
    amount:              params[:amount].to_f,
    expense_category_id: params[:expense_category_id].to_i
  )
  item = DB[:expense_items].order(:id).last
  erb :expense_row, layout: false, locals: { item: item }
end

delete "/expenses/:id" do
  DB[:expense_items].where(id: params[:id].to_i).delete
  ""
end

# Savings routes
post "/savings" do
  DB[:savings_allocations].insert(
    name: params[:name],
    rate: params[:rate].to_f
  )
  allocation   = DB[:savings_allocations].order(:id).last
  _, _, savings_pool = calculate_totals
  erb :savings_row, layout: false, locals: { allocation: allocation, savings_pool: savings_pool }
end

delete "/savings/:id" do
  DB[:savings_allocations].where(id: params[:id].to_i).delete
  ""
end

get "/summary" do
  @savings_allocations        = DB[:savings_allocations].all
  @total_income, @total_expenses, @savings_pool = calculate_totals
  erb :summary, layout: false
end