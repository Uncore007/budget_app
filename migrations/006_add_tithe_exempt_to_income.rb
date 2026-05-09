Sequel.migration do
  change do
    alter_table(:income_sources) do
      add_column :tithe_exempt, :boolean, default: false
    end
  end
end
