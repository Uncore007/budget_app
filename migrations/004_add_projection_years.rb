Sequel.migration do
  change do
    alter_table(:savings_allocations) do
      add_column :projection_years, Integer, default: 30
    end
  end
end
