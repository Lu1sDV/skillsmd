# Fixture for the upsert-all rule.

def sync_records
  # ruleid: ruby-mass-assignment-upsert-all
  Product.upsert_all(params[:products])
end

def sync_records_keyed
  # ruleid: ruby-mass-assignment-upsert-all
  Product.upsert_all(params[:products], unique_by: :sku)
end

def sync_records_safe
  rows = params.require(:products).map { |p| p.permit(:sku, :name).to_h }
  # ok: ruby-mass-assignment-upsert-all
  Product.upsert_all(rows, unique_by: :sku)
end
