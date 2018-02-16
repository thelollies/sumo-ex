class CreateWebsites < ActiveRecord::Migration[5.1]
  def change
    create_table :websites do |t|
      t.string  :domain
      t.integer :num_external_links
      t.integer :num_internal_links

      t.timestamps
    end

    add_index :websites, :domain, unique: true

  end
end
