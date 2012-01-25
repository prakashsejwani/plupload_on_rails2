class CreateDocuments < ActiveRecord::Migration
  def self.up
    create_table :documents do |t|
      t.integer :folder_id

      t.timestamps
    end
  end

  def self.down
    drop_table :documents
  end
end
