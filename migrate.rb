require "sequel"

DB = Sequel.connect("sqlite://budget.db")
Sequel.extension :migration
Sequel::Migrator.run(DB, "migrations")
puts "Migrations complete!"
