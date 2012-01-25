class Help < ActiveRecord::Base
has_attached_file :file, :whiny => false,
                            :url => "/system/files/:id/:basename.:extension",
                            :path => ":rails_root/public/system/files/:id/:basename.:extension"

  before_post_process :image?

  def image?
   !(file_content_type =~ /^image."/).nil?
  end
end
