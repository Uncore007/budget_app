require "sequel"

DB = Sequel.connect("sqlite://budget.db")

["Household", "Living", "Personal", "Personal Spending", "Debts"].each do |name|
  DB[:expense_categories].insert(name: name) unless DB[:expense_categories].where(name: name).first
end

puts "Seeded categories!"
