class Document < ActiveRecord::Base
  belongs_to :folder

  has_attached_file :file, :whiny => false,
                            :url => "/system/files/:id/:basename.:extension",
                            :path => ":rails_root/public/system/files/:id/:basename.:extension"

  before_post_process :image?

  def image?
   !(file_content_type =~ /^image."/).nil?
  end

   attr_accessor :tmp_upload_dir
  after_create  :clean_tmp_upload_dir
  
  # handle new param
  def fast_asset=(file)
    if file && file.respond_to?('[]')
      self.tmp_upload_dir = "#{file['filepath']}_1"
      tmp_file_path = "#{self.tmp_upload_dir}/#{file['original_name']}"
      FileUtils.mkdir_p(self.tmp_upload_dir)
      FileUtils.mv(file['filepath'], tmp_file_path)
      self.file = File.new(tmp_file_path)
      self.file_content_type = data[:content_type]
      self.file_file_name = data[:original_name]
    end
  end    
  
  private
  # clean tmp directory used in handling new param
  def clean_tmp_upload_dir
    FileUtils.rm_r(tmp_upload_dir) if self.tmp_upload_dir && File.directory?(self.tmp_upload_dir)
  end 

end
