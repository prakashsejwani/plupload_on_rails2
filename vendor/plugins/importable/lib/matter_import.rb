# Matter Import
class MatterImport < ExcelImport
  attr_accessor :employee_user_id,:company_id,:current_user_id,:header_array,:error_path

  CONTACT_DETAILS =
    ["first_name",  "last_name", "email","phone","contact_stage_id"]
  MATTER_DETAILS = ["matter_no","name","status_id","matter_category","matter_type_id","matter_date","employee_user_id"]
  MATTER_LITIGATION_DETAILS = ["plaintiff"]

  HEADERS =["matter_no","name","status_id","matter_category","matter_type_id","matter_date","first_name","last_name","contact_stage_id", "email","phone","employee_user_id","plaintiff"]

  EXCEL_HEADERS= ["*Matter Id","*Matter Name","Status",	"*Matter Category - Litigation/Non-litigation","*Matter type","Matter inception date (mm/dd/yyyy)","*FirstName","LastName","Contact Stage","#Email","#Phone","FirstName MiddleName LastName","Plaintiff / Defendant
    "]

  def initialize(current_user_id,employee_user_id,company_id,error_path,file_path=nil,options={})
    @current_user_id,@employee_user_id,@company_id =current_user_id, employee_user_id,company_id
    @error_path = error_path
    super(file_path,options)
    # validate_file unless @roo_object.is_a?(Array)
  end

  def validate_file
    return "Invalid file formating" if @header.size != EXCEL_HEADERS.size
    @header.each_with_index do |h,i|
      return "Invalid file formating" if h != EXCEL_HEADERS[i]
      return
    end
  end

  def import_object_record
    # ActiveRecord::Base.transaction do
    @object_records.each do |object|

      matter = Matter.new(object[0])
      index = object[3]
      contact_details = object[1]

      uname = (contact_details["first_name"].to_s + ' ' +  contact_details["last_name"].to_s).strip
      contacts = Contact.find_by_sql("SELECT * FROM contacts WHERE ((trim(contacts.first_name) || ' ' || trim(coalesce(contacts.last_name, ' ')) iLike '#{uname}') ) AND company_id = #{@company.id} AND (email = '#{contact_details["email"]}' OR
        phone = '#{contact_details["phone"]}') LIMIT 1")
      if contacts.present?
        contact = contacts[0]
        matter.contact_id = contact.id
        object[0]["contact_id"] = contact.id
      else
        contact = Contact.new(contact_details)
        if contact.valid?
          matter.contact_id = 0
          object[0]["contact_id"] = contact.id

        else
          @invalid_records << [matter,@roo_object.row(index+1+@first_row),contact.errors.full_messages.uniq.to_s]
          next
        end
      end
      begin

        if matter.valid? && (matter.contact_id == 0 ? contact.save : contact.deleted_at.blank?)
          if matter.contact_id == 0
            matter.contact_id = contact.id
            object[0]["contact_id"] = contact.id
          end

          matter,success = Matter.save_with_contact_and_opportunity( {"matter"=>object[0],"contact"=>contact.attributes}, object[0]["employee_user_id"], nil )
          if success
            @valid_records << [matter,@roo_object.row(index+1+@first_row)]
            #create matter litigation entry only if category is litigation
            matter.matter_litigations.create("plaintiff"=>object[2]["plaintiff"],"company_id"=>object[2]["company_id"]) if matter.matter_category == "litigation"
          else
            @invalid_records << [matter,@roo_object.row(index+1+@first_row),matter.errors.full_messages.uniq.to_s]

           contact.destroy_without_callbacks! if !contacts.present? && contact.id!=nil
          end
        else

          errors = matter.errors.full_messages.uniq.to_s
          errors << "This Contact is deactivated" if !contact.deleted_at.blank?
          errors << contact.errors.full_messages.uniq.to_s if matter.contact_id == 0
          #in below statement contact.valid? is added cause if contact is invalid it would throw the errors related to contact from matter model(Primary Contact error)
          @invalid_records << [matter,@roo_object.row(index+1+@first_row),errors]
          # if matter is invalid and contact is also invalid & older same record is not present in database contact.destroy will throw error thus checking if contact is valid

          contact.destroy_without_callbacks!  if !contacts.present? && contact.id!=nil
        end
      rescue
        errors= ""
        errors << contact.errors.full_messages.uniq.to_s unless contact.valid?
        errors << matter.errors.full_messages.uniq.to_s unless matter.valid?
        @invalid_records << [matter,@roo_object.row(index+1+@first_row),errors]
      end
    end
    #end
  end

  def import_records
    @valid_records = []
    @invalid_records= []
    @object_records = []
    data = import_excel
    @header_array = HEADERS
    record_hash(HEADERS)
    @company = Company.find(company_id)
    @user = User.find(employee_user_id)
    @current_user = User.find(@current_user_id)
    @contact_stage = {}
    @company.contact_stages.each {|cs| @contact_stage[cs.lvalue]=cs.id}
    @matter_status = {}
    @default_matter_status = @company.matter_statuses.find_by_lvalue("Open")
    @company.matter_statuses.each {|ms|@matter_status[ms.lvalue]=ms.id}
    @company_liti_types = {}
    @company.liti_types.each {|ms|@company_liti_types[ms.lvalue]=ms.id}
    @company_nonliti_types = {}
    @company.nonliti_types.each {|ms|@company_nonliti_types[ms.lvalue]=ms.id}
    User.current_company = @company
    User.current_user = @current_user
    @hash_records.each_with_index do |record,index|
      flag = false
      # if assigned to is present find out user id from employees table based on first name or last name
      record["phone"] = set_phone_no(record["phone"])

	    if !record["employee_user_id"].nil? &&  !record["employee_user_id"].empty?

        employee_user_id = User.find_by_sql("SELECT * FROM employees WHERE ((trim(employees.first_name) || ' ' || trim(employees.last_name) iLike '#{record["employee_user_id"]}') ) AND company_id = #{@company.id} LIMIT 1")
		    if employee_user_id.empty?
          record["errors"] << "Invalid Lead Lawyer."
          flag = true
			  else
				  record["employee_user_id"] = employee_user_id.first.user_id
			  end
      else
		    record["employee_user_id"] = @user.id
      end

      # for managing contact stage id by default is lead id
      if !record["contact_stage_id"].nil? && !record["contact_stage_id"].empty?
        if @contact_stage.keys.include?(record["contact_stage_id"])
          record["contact_stage_id"] = @contact_stage[record["contact_stage_id"]]
        else
          record["errors"] << "Invalid Contact Stage."
          flag = true
        end
      else
        record["contact_stage_id"] = @contact_stage["Lead"]
      end

      #For Matter Category
      if record["matter_category"].present?
        unless record["matter_category"].strip.downcase.eql?("litigation") || record["matter_category"].strip.downcase.eql?("non-litigation")
          record["errors"] << "Invalid Matter Category."
          flag = true
        else
          record["matter_category"] = record["matter_category"].strip.downcase
        end
      else
        record["errors"] << "Matter Category is required."
        flag = true
      end

      #For Matter Type
      if record["matter_type_id"].present?
        if record["matter_category"].present? && record["matter_category"].strip.downcase.eql?("litigation")
          if @company_liti_types.keys.include?(record["matter_type_id"])
            record["matter_type_id"] = @company_liti_types[record["matter_type_id"]]
          else
            record["errors"] << "Matter type is Invalid."
            flag = true
          end
        elsif record["matter_category"].present? && record["matter_category"].strip.downcase.eql?("non-litigation")
          if @company_nonliti_types.keys.include?(record["matter_type_id"])
            record["matter_type_id"] = @company_nonliti_types[record["matter_type_id"]]
          else
            record["errors"] << "Matter type is Invalid."
            flag = true
          end
        end
      else
        record["errors"] << "Matter Type cannot be blank."
        flag = true
      end

      # For Matter Status by default is open
      if record["status_id"].present?
        if @matter_status.keys.include?(record["status_id"])
          record["status_id"] = @matter_status[record["status_id"]]
        else
          record["errors"] << "Matter status is Invalid."
          flag = true
        end
      else
        record["status_id"] = @default_matter_status.try(:id)
      end

      #plaintiff or defendant for litigation
      if record["matter_category"].present?
        if record["matter_category"].strip.downcase.eql?("litigation")
          if record["plaintiff"].present?
            if record["plaintiff"].strip.downcase.eql?('plaintiff')
              record["plaintiff"] = true
            else
              record["plaintiff"] = false
            end
          end
        end
      end

      #Matter inception date
      begin
        record["matter_date"] = record["matter_date"].present? ? Date.parse(record["matter_date"]).to_date.strftime("%m/%d/%Y") : Date.today
      rescue Exception => exc
        record["errors"] << "Invalid inception date"
        flag = true
      end
      if flag
        @invalid_records <<['',@roo_object.row(index+1+@first_row),record["errors"].join(",")]
      else
        contact_details = parse_contact_details(record,@company.id)
        matter_details = parse_matter_details(record,@company.id)
        matter_litigation_details =  parse_matter_litigation_details(record,@company.id)
        @object_records <<  [matter_details,contact_details,matter_litigation_details,index]
      end
    end

    # insert Into Database and create valid and invalid record
    import_object_record
    # Create Excel sheet from invalid record
    invalid_records_to_excel(@error_path,@invalid_records,["Error",EXCEL_HEADERS].flatten)
  end

  def set_phone_no(val)
    if val.nil? || val.empty?
      val=''
    else
      val.to_s.gsub('.0', '''').to_s
    end
  end

  def parse_contact_details(record,company_id)
    contact_info= {}
    CONTACT_DETAILS.each do |cd|
      contact_info[cd] = record[cd]
    end
    contact_info["status_type"] = ''
    contact_info["company_id"] = company_id
    contact_info["assigned_to_employee_user_id"] = 16
    contact_info
  end

  def parse_matter_details(record,company_id)
    matter_details =  {}
    MATTER_DETAILS.each do |ad|
      matter_details[ad]= record[ad]
    end
    matter_details["company_id"] = company_id
    matter_details["is_internal"]= false
    matter_details["created_by_user_id"] = @current_user_id
    matter_details
  end

  def parse_matter_litigation_details(record,company_id)
    matter_litigation_details = {}
    MATTER_LITIGATION_DETAILS.each do |cd|
      matter_litigation_details[cd]= record[cd]
    end
    matter_litigation_details["company_id"] = company_id
    matter_litigation_details
  end

end

