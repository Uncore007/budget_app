Sequel.migration do
  change do
    alter_table(:savings_allocations) do
      add_column :weight, Integer, null: false, default: 1
    end
  end
end
