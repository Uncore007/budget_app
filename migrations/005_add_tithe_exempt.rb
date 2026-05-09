Sequel.migration do
  change do
    alter_table(:expense_categories) do
      add_column :tithe_exempt, :boolean, default: false
    end
  end
end
