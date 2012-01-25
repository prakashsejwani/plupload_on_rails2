class AddAttachmentsFileToHelp < ActiveRecord::Migration
  def self.up
    add_column :helps, :file_file_name, :string
    add_column :helps, :file_content_type, :string
    add_column :helps, :file_file_size, :integer
    add_column :helps, :file_updated_at, :datetime
  end

  def self.down
    remove_column :helps, :file_file_name
    remove_column :helps, :file_content_type
    remove_column :helps, :file_file_size
    remove_column :helps, :file_updated_at
  end
end
