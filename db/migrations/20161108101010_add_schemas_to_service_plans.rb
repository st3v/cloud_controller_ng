Sequel.migration do
  change do
    add_column :service_plans, :provision_schema, String, text: true, null: true
    add_column :service_plans, :update_schema, String, text: true, null: true
    add_column :service_plans, :bind_schema, String, text: true, null: true
  end
end
