class CreateLinks < ActiveRecord::Migration[6.0]
  def change
    create_table :links, id: false do |t|
      t.bigint :link_id, primary_key: true
      t.string :name, null: false
      t.string :secret, null: false, index: {unique: true}
      t.string :password_digest, null: true

      t.timestamps
    end
  end
end
