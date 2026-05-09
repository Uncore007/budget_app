require "sinatra"
require "sinatra/reloader" if development?
require "sequel"
require "date"

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

  # Returns array of [with_returns, contributions_only] pairs, one per year up to `years`.
  def investment_projection(monthly_amount, annual_rate_pct, years: 30)
    r = annual_rate_pct.to_f / 100.0 / 12.0
    (1..years).map do |yr|
      n = yr * 12
      with_returns = r > 0 ? monthly_amount * ((1 + r)**n - 1) / r : monthly_amount * n
      [with_returns.round(2), (monthly_amount * n).round(2)]
    end
  end

  # Returns array of [label, cumulative_total] pairs, one per month until goal_date.
  def spending_projection(monthly_amount, goal_date_str)
    return [] if goal_date_str.nil? || goal_date_str.strip.empty?
    today = Date.today
    goal  = begin; Date.parse(goal_date_str); rescue ArgumentError; nil; end
    return [] if goal.nil? || goal <= today
    months = (goal.year - today.year) * 12 + (goal.month - today.month)
    return [] if months <= 0
    (1..months).map do |m|
      [(today >> m).strftime("%b %Y"), (monthly_amount * m).round(2)]
    end
  end

  def number_with_commas(n)
    ("%.2f" % n).reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end

get "/" do
  @savings_allocations = DB[:savings_allocations].all
  @categories          = DB[:expense_categories].all
  @expense_items       = DB[:expense_items].all
  @total_income, @total_expenses, @savings_pool = calculate_totals
  erb :index
end

# Income routes
get "/income" do
  @income_sources = DB[:income_sources].all
  erb :income
end

post "/income" do
  DB[:income_sources].insert(
    name:     params[:name],
    amount:   params[:amount].to_f,
    tax_rate: params[:tax_rate].to_f / 100
  )
  source = DB[:income_sources].order(:id).last
  erb :income_row, layout: false, locals: { source: source }
end

get "/income/:id/edit" do
  source = DB[:income_sources].where(id: params[:id].to_i).first
  erb :income_edit_row, layout: false, locals: { source: source }
end

get "/income/:id" do
  source = DB[:income_sources].where(id: params[:id].to_i).first
  erb :income_row, layout: false, locals: { source: source }
end

patch "/income/:id" do
  DB[:income_sources].where(id: params[:id].to_i).update(
    name:     params[:name],
    amount:   params[:amount].to_f,
    tax_rate: params[:tax_rate].to_f / 100
  )
  source = DB[:income_sources].where(id: params[:id].to_i).first
  erb :income_row, layout: false, locals: { source: source }
end

delete "/income/:id" do
  DB[:income_sources].where(id: params[:id].to_i).delete
  ""
end

# Expense category routes
post "/expense_categories" do
  DB[:expense_categories].insert(name: params[:name])
  category = DB[:expense_categories].order(:id).last
  erb :expense_category, layout: false, locals: { category: category, items: [] }
end

delete "/expense_categories/:id" do
  DB[:expense_items].where(expense_category_id: params[:id].to_i).delete
  DB[:expense_categories].where(id: params[:id].to_i).delete
  ""
end

# Expense routes
get "/expenses" do
  @categories   = DB[:expense_categories].all
  @expense_items = DB[:expense_items].all
  erb :expenses
end

post "/expenses" do
  DB[:expense_items].insert(
    name:                params[:name],
    amount:              params[:amount].to_f,
    expense_category_id: params[:expense_category_id].to_i
  )
  item = DB[:expense_items].order(:id).last
  erb :expense_row, layout: false, locals: { item: item }
end

get "/expenses/:id/edit" do
  item = DB[:expense_items].where(id: params[:id].to_i).first
  erb :expense_edit_row, layout: false, locals: { item: item }
end

get "/expenses/:id" do
  item = DB[:expense_items].where(id: params[:id].to_i).first
  erb :expense_row, layout: false, locals: { item: item }
end

patch "/expenses/:id" do
  DB[:expense_items].where(id: params[:id].to_i).update(
    name:   params[:name],
    amount: params[:amount].to_f
  )
  item = DB[:expense_items].where(id: params[:id].to_i).first
  erb :expense_row, layout: false, locals: { item: item }
end

delete "/expenses/:id" do
  DB[:expense_items].where(id: params[:id].to_i).delete
  ""
end

# Savings routes
get "/savings" do
  @savings_allocations = DB[:savings_allocations].all
  @total_income, @total_expenses, @savings_pool = calculate_totals
  erb :savings
end

post "/savings" do
  DB[:savings_allocations].insert(name: params[:name], rate: 0.0, weight: 50, saving_type: "other")
  allocation   = DB[:savings_allocations].order(:id).last
  total_weight = DB[:savings_allocations].sum(:weight).to_f
  _, _, savings_pool = calculate_totals
  pct    = total_weight > 0 ? (allocation[:weight] / total_weight * 100).round(1) : 0
  amount = pct / 100.0 * savings_pool
  erb :savings_card, layout: false, locals: { allocation: allocation, pct: pct, amount: amount }
end

post "/savings/weights" do
  (params["weight"] || {}).each do |id, weight|
    type = (params.dig("type", id) || "other")
    DB[:savings_allocations].where(id: id.to_i).update(
      weight:      [[weight.to_i, 1].max, 100].min,
      saving_type: type,
      return_rate:      type == "investment" ? params.dig("return_rate", id).to_f      : nil,
      projection_years: type == "investment" ? [[params.dig("projection_years", id).to_i, 1].max, 50].min : nil,
      goal_date:        type == "spending"   ? params.dig("goal_date", id)            : nil
    )
  end
  redirect "/savings"
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