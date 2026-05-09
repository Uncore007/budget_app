Sequel.migration do
  change do
    alter_table(:savings_allocations) do
      add_column :saving_type, String, default: "other"
      add_column :return_rate, Float
      add_column :goal_date,   String
    end
  end
end
