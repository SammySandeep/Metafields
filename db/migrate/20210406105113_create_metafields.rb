class CreateMetafields < ActiveRecord::Migration[5.2]
  def change
    create_table :metafields do |t|
      t.string :key
      t.string :namespace, :default => "productspecs"
      t.string :value

      t.timestamps
    end
  end
end
