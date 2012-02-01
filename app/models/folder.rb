class Folder < ActiveRecord::Base
has_many :documents, :dependent => :destroy
accepts_nested_attributes_for :documents, :allow_destroy => true
acts_as_importable :import_fields => ["name"]
end
