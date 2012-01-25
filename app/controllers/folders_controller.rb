class FoldersController < ApplicationController
  # GET /folders
  # GET /folders.xml

  def index
    @folders = Folder.all
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @folders }
   #   format.pdf  { render :pdf => "my" ,:layout => 'pdf'}
#        render :pdf => "index", # pdf will download as my_pdf.pdf
#        :layout => 'pdf', # uses views/layouts/pdf.haml
#        :show_as_html => params[:debug].present? # renders html version if you set debug=true in URL
#      end
    end
  end
def create_product_pdf
  source_url = root_url
  output_pdf = "output_#{Time.now.to_i}.pdf"
  destination = "#{::Rails.root.to_s}/public/pdfs/#{output_pdf}"
  command_line = %Q{/usr/bin/wkhtmltopdf #{source_url} #{destination}}
  
  # Execute wkhtmltopdf
  pdf = `#{command_line}`
  save_path = Rails.root.join('',output_pdf)
File.open(save_path, 'wb') do |file|
  file << output_pdf 
end
  send_file(pdf, :type => 'application/pdf', :disposition => "inline", :filename =>  output_pdf )
  redirect_to "/folders"
end
  # GET /folders/1
  # GET /folders/1.xml
  def show
    @folder = Folder.find(params[:id])
    @documents = @folder.documents
     @i = 0 
    if params[:files]
			flash[:notice] = "#{params[:files]} files are uploaded"
    end
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @folder }
       format.pdf do
        render :pdf => "my_pdf", # pdf will download as my_pdf.pdf
        :layout => 'pdf', # uses views/layouts/pdf.haml
        :show_as_html => params[:debug].present? # renders html version if you set debug=true in URL
      end
    end  
  end

  # GET /folders/new
  # GET /folders/new.xml
  def new
    @folder = Folder.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @folder }
    end
  end

  # GET /folders/1/edit
  def edit
    @folder = Folder.find(params[:id])
  end

  # POST /folders
  # POST /folders.xml
  def create
    @folder = Folder.new(params[:folder])

    respond_to do |format|
      if @folder.save
        format.html { redirect_to(@folder, :notice => 'Folder was successfully created.') }
        format.xml  { render :xml => @folder, :status => :created, :location => @folder }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @folder.errors, :status => :unprocessable_entity }
      end
    end
  end

  def multiple_uploads
    @folder = Folder.find(params[:id]) 
    @folder.documents.build
  end

  def do_multiple_upload
   #hash_structure = params["folder"]["documents_attributes"]
   @folder = Folder.find(params[:id].to_i)
   @i = params[:i].to_i
#   params["folder"] = {}
#   params["folder"]["documents_attributes"] = {}
#   params["folder"]["documents_attributes"].merge!({"0" => {"file" => params[:file]}})
   puts "===----------------------#{params}" 
   if params.has_key?(:asset)
   params[:asset].each do |data|
   @document = @folder.documents.build
   @document.tmp_upload_dir = "#{data['filepath']}_1"
   
   @document.file =  File.new(data[:filepath])
   # @document.fast_asset = data
    # detect Mime-Type (mime-type detection doesn't work in flash)
   # @document.file_content_type = data[:content_type]
    
    @document.save!
    end
   else
    @document = @folder.documents.build
    @document.name = params[:doc_name]
    @document.file = params[:file] if params.has_key?(:file )
    # detect Mime-Type (mime-type detection doesn't work in flash)
    @document.file_content_type = MIME::Types.type_for(params[:name]).to_s if params.has_key?(:name)

    @document.save!
   end
 respond_to :js
   @document = nil
    @folder = nil
    params = nil
   GC.start
  
  end

  # PUT /folders/1
  # PUT /folders/1.xml
  def update
    @folder = Folder.find(params[:id])

    respond_to do |format|
      if @folder.update_attributes(params[:folder])
        format.html { redirect_to(@folder, :notice => 'Folder was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @folder.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /folders/1
  # DELETE /folders/1.xml
  def destroy
    @folder = Folder.find(params[:id])
    @folder.destroy

    respond_to do |format|
      format.html { redirect_to(folders_url) }
      format.xml  { head :ok }
    end
  end
end
