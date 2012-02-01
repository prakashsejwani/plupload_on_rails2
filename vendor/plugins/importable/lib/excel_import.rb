# mappings
# if mapper_name is not present take as column name
# mapper_name is used to generate hash key
# required true default is false
# it checks wether data is present or not 
# if data is not present it will sets into invalid data may be with message
# {0=>{:mapper_name=>"",:required=>true}}
# 
class Array
  def row(index)
    self[index]
  end
end

class ExcelImport
  attr_accessor :records,:mappings,:roo_object
  attr_accessor :first_row,:first_column,:last_row,:last_column,:header_row
  attr_accessor :header,:array_records,:hash_records
  attr_accessor :valid_records,:invalid_records,:object_records
  
  def initialize(path,opts= {})
    @mappings= {}
    @header = []
    @records = []
    # if data comes from array of records instead of excel
    if path.is_a?(Array) 
      path[0].map {|h| @header << h.try(:capitalize)}
      @first_row = 0
      @last_row  = path.size - 1
      @first_column = 0
      @last_column = 0
      @roo_object = path
    elsif File.exist?(path) && File.extname(path)==".csv"
      csv_records = parse_csv_file(path)
      csv_records[0].map {|h| @header << h}
      @first_row = 0
      @last_row  = csv_records.size - 1
      @first_column = 0
      @last_column = 0
      @roo_object = csv_records
    else
      generate_roo_objects(path) 
      set_bounds(opts["boundry"]) 
      set_mappings(opts)
    end
  end
  # For parsing csv file
  def parse_csv_file(file_path)
    csv_records = []
 
    CSV::Reader.parse(File.new(file_path, "r").read) do |row|
      csv_records << row
    end
    csv_records
  end
  # it will create roo objects depends upon file type
  def generate_roo_objects(path)
    if File.exist?(path)
      ext = File.extname(path)          
      if ext == ".xls"
        @roo_object = Excel.new(path)
      elsif ext == ".ods"
        @roo_object = Openoffice.new(path)
      elsif ext == ".xlsx"
        @roo_object = Excelx.new(path)
      end
  
    end  
  end

  #Helps us to set boundry of excel sheet
  # if header starts from particular row of data start from
  # particular row we can specifies
  def set_bounds(boundry)
    @first_row = boundry && boundry["first_row"] || @roo_object.first_row 
    @last_row = boundry && boundry["last_row"]  || @roo_object.last_row
    @first_column = boundry && boundry["first_column"] || @roo_object.first_column
    @last_column = boundry && boundry["last_column"] ||@roo_object.last_column
    @header_row  =  boundry && boundry["header_row"] || @roo_object.first_row 
  end

   
  # setting up initial mapping
  # taking up first row i.e considering header
  # and setting up column_name,mapper_name 
  def set_mappings(opts)
   @roo_object.row(@header_row).each_with_index do |cell,i|
       @mappings[i]= {"column_name"=>cell,"mapper_name"=>cell,"required"=>false,"type"=>nil}
    end
    set_option_mappings(opts)
    set_header
  end
 
  # @mappings looks like
  # @mappings = {"Name"=>{:column_name=>"Name", :mapper_name=>"Name", :required=>false}, "Price"=>{:column_name=>"Price", :mapper_name=>"Price", :required=>false}, "Category"=>{:column_name=>"Category", :mapper_name=>"Category", :required=>false}}
  # if opts["mappings"] 
  # opts["mappings"] =[{"column_name"=>"Name",:mapper_name=>"first_name",:required=>true}]
  def set_option_mappings(opts)
    
    if opts["mappings"] && opts["mappings"].is_a?(Array)
      opts["mappings"].each do |opt| 
        # mapping @mappings["Name"]
        mapping = @mappings.select {|k,v| v["column_name"].strip == opt["column_name"].strip }.flatten  
        if mapping
          @mappings[mapping[0]]["mapper_name"]= opt["mapper_name"] if opt["mapper_name"]
          @mappings[mapping[0]]["required"]= opt["required"] if opt["required"]
          @mappings[mapping[0]]["type"]= opt["type"] if opt["type"]
        end
      end
    end
  end
  
  # set header 
  # @header = ["name","price",..]  
  def set_header
    @mappings.each {|k,v| @header[k] = v["mapper_name"]}
  end
  
  def import_excel
    @array_records = []
    @records = []
    (@first_row+1..@last_row).to_a.each do |r|
      if @roo_object.is_a?(Array)
        @array_records << @roo_object.row(r)
      else
        @array_records << format_row(@roo_object.row(r))
      end
    end
  end

  # formating row depending upon type
  def format_row(row)
    row.each_with_index do |r,i|
      formatted_row= []
	 unless r.nil? 	
      if @mappings[i]["type"] == "Integer"
        row[i] = r.to_i
      elsif @mappings[i]["type"] == "Float"
        row[i] = r.to_f
      elsif @mappings[i]["type"] == "Date"
        row[i] = r
      else
        row[i] = r.to_s
      end
	 end	
    end
    row
  end

  # create hash with mapping name and array records
  #{"Name"=>"Amar"}
  # if mapping is provided it take care of mapper name  
  def set_record
    @array_records.map do |row|
      record = {}
      row.each_with_index do |cell,index| 
        record[@header[index]] = cell
      end
      @records << record  
    end
  end

  #create records hash depending upon by passing array of records
  def record_hash(header_array)
    @hash_records = []
    @array_records.each do |ex_record|
	    record = Hash[header_array.zip(ex_record)]
      record["errors"] = [] 
      record.each do |key,value|
        value.strip! if !value.nil? && value!=[]
      end
      @hash_records << record
    end
  end

  
  # Generalized method that saves record and set to valid or invalid record
  def import_object_record
   @object_records.each do |object|
     if object.save
      @valid_records << object
     else
      @invalid_records << object
     end
   end
 end

 # passing file name
 # passing rows looks like [["a",123],["aa",456]]
 # passing header to be print [["Name","Age"]]
 def self.to_excel(file_name,rows,headers=nil)
  file_name = "#{file_name}"
  book = Spreadsheet::Workbook.new
  sheet1 = book.create_worksheet
   header_row = 0 

   unless headers.nil?
    format =Spreadsheet::Format.new :color => :black, :weight=> :bold,  :size => 11 , :horizontal_align=>:centre ,:text_wrap => true
      if headers[0].is_a?(Array)  
        headers.each do |header|
          sheet1.row(header_row).default_format = format
          sheet1.row(header_row).concat header      
          header_row = header_row+1
        end
     else
       sheet1.row(0).default_format = format
       sheet1.row(0).concat headers      
       header_row = header_row+1
     end  
   end  
    
   rows.each_with_index do |row,index| 
     sheet1.row(header_row+index).concat row
   end 
      book.write file_name
  end
  
  # hash_record contains records but in order
  # so by passing array_header we will bring into order
  # like record {"surname"=>"daxini","name"=>"amar"}
  # array_header =  ["name","surname"]
  # ["amar","daxini"]
  # It is helpful if data is not coming from Excel but come from form params

  #TODO Refactor in one line  
  def self.rearrange_hash_to_array(hash_record,array_header)
    rearrange_array = []
     array_header.each do |a|  
      rearrange_array << hash_record[a]
     end 
    rearrange_array 
  end

  # for manipulating data
  def invalid_records_to_excel(file_name,rows,headers=nil)
    ExcelImport.to_excel(file_name,rows.map{|r| [r[2],r[1]].flatten},headers)
  end
end

