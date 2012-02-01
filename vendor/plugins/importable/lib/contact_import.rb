# STANDARD WAY O DO


# Contact Import
class ContactImport < ExcelImport
  attr_accessor :employee_user_id,:company_id,:header_array,:error_path
  CONTACT_DETAILS = 
["salutation_id", "first_name",  "middle_name", "last_name", "nickname" ,"email","phone", "mobile","fax","website" ,"title","assigned_to_employee_user_id","alt_email","contact_stage_id"]

  ADDRESS_DETAILS = ["street", "city", "country", "zipcode", "state"]
  CONTACT_ADDITIONAL_DETAILS = ["business_street", "business_city", "business_state","business_country", "business_postal_code", "business_fax", "business_phone", "businessphone2","linked_in_account", "twitter_account", "facebook_account", "skype_account","others_1","others_2","others_3","others_4","others_5","others_6"]
  
  HEADERS = ["salutation_id","first_name","middle_name","last_name","email","phone","nick_name","alt_email","source","source_details","assigned_to_employee_user_id","contact_stage_id","company_id","title","street","city","state","zipcode","business_fax","business_phone","businessphone2","website","comments","business_street","business_city","business_state","business_postal_code","mobile","fax","skype_account","linked_in_account","facebook_account","twitter_account","others_1","others_2","others_3","others_4","others_5","others_6"]

EXCEL_HEADERS= ["Salutation","*First Name","Middle Name","Last Name","#Primary Email","#Primary Phone","Nick Name",	"Alternate Email","Source","Source Details","Assigned To","Contact Stage","Company","Title","Street","City","State","Zip Code","Fax","Alternate Phone 1","Alternate Phone 2",	"Website","Comments","Street","City","State",	"Zip Code","Mobile","Fax","Skype Account","Linked In Account","Facebook Account","Twitter Account","Other1","Other2","Other3","Other4","Other5","Other6"]

  
  def initialize(employee_user_id,company_id,error_path,file_path=nil,options={})

    @employee_user_id,@company_id = employee_user_id,company_id
    @error_path = error_path
    super(file_path,options)
#    validate_file unless file_path.is_a?(Array)
  end

  def validate_file
     raise "Invalid file formating" if @header.size != EXCEL_HEADERS.size
      @header.each_with_index do |h,i|
      raise "Invalid file formating" if h != EXCEL_HEADERS[i] 
      return
    end    
  end

  def import_object_record
    ActiveRecord::Base.transaction do
      @object_records.each do |object|
          contact = object[0]
          address = contact.build_address(object[1])
          contact_additonal_field = contact.build_contact_additional_field(object[2])
          index = object[3]
          if contact.valid? 
            begin 
            if contact.save
              @valid_records << [contact,@roo_object.row(index+1+@first_row)]
            else
               @invalid_records << [contact,@roo_object.row(index+1+@first_row),contact.errors.full_messages.uniq]
            end
           rescue
             @invalid_records << [contact,@roo_object.row(index+1+@first_row),contact.errors.full_messages.uniq]
           end            
          else
            @invalid_records << [contact,@roo_object.row(index+1+@first_row),contact.errors.full_messages.uniq]
          end
     end
   end
  end
  
  def import_records
    @valid_records = []
    @invalid_records= []
    @object_records = []
    import_excel
    @header_array = HEADERS 
    record_hash(HEADERS)
    @company = Company.find(company_id)
    @user = User.find(employee_user_id)
    @contact_stage = {}
    @company.contact_stages.each {|cs| @contact_stage[cs.alvalue]=cs.id}
    @salutaion = {}
    @company.salutation_types.each {|st| @salutaion[st.alvalue] = st.id}
    @contact_source = {}
    @company.company_sources.each {|cs| @contact_source[cs.alvalue] = cs.id}
    @hash_records.each_with_index do |record,index|
  	  
    # if assigned to is present find out user id from employees table based on first name or last name
       record["phone"] = set_phone_no(record["phone"])
       record["business_phone"] = set_phone_no(record["business_phone"])
       record["businessphone2"] = set_phone_no(record["businessphone2"])

	  if !record["assigned_to_employee_user_id"].nil? &&  !record["assigned_to_employee_user_id"].empty?
		  if record["assigned_to_employee_user_id"].is_a?(String) && record["assigned_to_employee_user_id"].downcase == "none"
			  record["assigned_to_employee_user_id"] = nil
		  else
        assigned_to = User.find_by_sql("SELECT user_id FROM employees WHERE ((trim(employees.first_name) || ' ' || trim(employees.last_name) iLike '#{record["assigned_to_employee_user_id"]}') ) AND company_id = #{@company.id} LIMIT 1")
		    if assigned_to.empty?
			     record["errors"] << "Assigned To Is Invalid"
          
    		   @invalid_records <<['', @roo_object.row(index+1+@first_row),record["errors"]]
				   next
			  else
				  record["assigned_to_employee_user_id"] = assigned_to.first
			  end
			end
	  else
		  record["assigned_to_employee_user_id"] = @user.id
	  end

		# for managing contact stage id by default is lead id
  	if !record["contact_stage_id"].nil? && !record["contact_stage_id"].empty?
  		if @contact_stage.keys.include?(record["contact_stage_id"])
  			record["contact_stage_id"] = @contact_stage[record["contact_stage_id"]]
  		else
  			record["errors"] << "Invalid Contact Stage."
        @invalid_records <<['',@roo_object.row(index+1+@first_row),record["errors"]]
  			next
  		end
  	else
		  record["contact_stage_id"] = @contact_stage["Lead"]
	  end

    # contact source
	  if !record["source"].nil? && !record["source"].empty?
      if @contact_source.keys.include?(record["source"])
  			record["source"] = @contact_source[record["source"]]
      else
        record["errors"] << "Invalid Contact Source."
        @invalid_records <<['',@roo_object.row(index+1+@first_row),record["errors"]]
  			next
      end  
    end
  
	  contact_info = ContactImport.parse_contact_details(record,@company.id)
    address_details = ContactImport.parse_address_details(record,@company.id)
    contact_additional_details = ContactImport.parse_contact_additional_details(record,@company.id)
  
	  @object_records <<  [Contact.new(contact_info),(address_details),(contact_additional_details),index]
  end
  # insert Into Database and create valid and invalid record
 
  import_object_record
  # Create Excel sheet from invalid record
  invalid_records_to_excel(@error_path,@invalid_records,["Error",EXCEL_HEADERS].flatten)
 
 end
  
 def set_phone_no(val)
   if val.nil? || val.empty? 
    val=nil
   else 
    val.to_s.gsub('.0', '''').to_s  
   end
 end
 

 def self.parse_contact_details(record,company_id)
  contact_info= {}
  CONTACT_DETAILS.each do |cd|
    contact_info[cd] = record[cd]
  end
  contact_info["status_type"] = ''
  contact_info["company_id"] = company_id
  contact_info

 end

 def self.parse_address_details(record,company_id)
   address_details =  {}
   ADDRESS_DETAILS.each do |ad|
    address_details[ad]= record[ad] 
   end 
   address_details["company_id"] = company_id
   address_details    
 end

 def self.parse_contact_additional_details(record,company_id)
   contact_additional_details = {}
   CONTACT_ADDITIONAL_DETAILS.each do |cd|
    contact_additional_details[cd]= record[cd] 
   end 
   contact_additional_details["company_id"] = company_id
   contact_additional_details    
 end 

end
