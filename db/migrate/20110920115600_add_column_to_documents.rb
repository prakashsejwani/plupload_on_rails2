class AddColumnToDocuments < ActiveRecord::Migration
  def self.up
   add_column :documents, :name, :string
  end

  def self.down
   remove_column :documents, :name, :string
  end
end
