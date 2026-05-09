Sequel.migration do
  up do
    create_table :income_sources do
      primary_key :id
      String :name, null: false
      Float :amount, null: false
      Float :tax_rate, default: 0.0
    end

    create_table :expense_categories do
      primary_key :id
      String :name, null: false
    end

    create_table :expense_items do
      primary_key :id
      foreign_key :expense_category_id, :expense_categories
      String :name, null: false
      Float :amount, null: false
    end

    create_table :savings_allocations do
      primary_key :id
      String :name, null: false
      Float :rate, null: false
    end

    create_table :settings do
      primary_key :id
      String :key, null: false, unique: true
      String :value
    end
  end

  down do
    drop_table :settings
    drop_table :savings_allocations
    drop_table :expense_items
    drop_table :expense_categories
    drop_table :income_sources
  end
end
