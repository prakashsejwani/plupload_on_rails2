class Timeimport < ExcelImport
  attr_accessor :current_user_id,:employee_user_id,:company_id,:header_array,:error_path,:employee_user

  TIME_ENTRY_DETAILS = ["time_entry_date","employee_user_id","matter_id","contact_id","activity_type","description","actual_duration","actual_activity_rate","billing_method_type","final_billed_amount"]

  HEADERS = ["time_entry_date","employee_user_id","matter_no","name","first_name","middle_name","last_name","activity_type","description","actual_duration","actual_activity_rate","billing_method_type","final_billed_amount"]

  EXCEL_HEADERS= ["*Date","*FirstName MiddleName LastName","*Matter ID","*Matter Name","*FirstName","MiddleName","LastName",	"*Activity Type","*Description","*Duration","*Rate/Hr($)","Billable","Final Amount($)"]

  def initialize(current_user_id,employee_user_id,company_id,error_path,file_path=nil,options={})
    @employee_user_id,@company_id = employee_user_id,company_id
    @error_path = error_path
    @current_user_id = current_user_id
    @employee_user = User.find(@employee_user_id)
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
        begin
          time_entry = object[0]
          index = object[1]
          if time_entry.valid?
            time_entry.created_by_user_id = @current_user_id
            time_entry.current_lawyer = @current_user_id
            if time_entry.save
              @valid_records << [time_entry,@roo_object.row(index+1+@first_row)]
            else
              @invalid_records << [time_entry,@roo_object.row(index+1+@first_row),time_entry.errors.full_messages.uniq]
            end
          else
            @invalid_records << [time_entry,@roo_object.row(index+1+@first_row),time_entry.errors.full_messages.uniq]
          end
        rescue
          @invalid_records << [time_entry,@roo_object.row(index+1+@first_row),time_entry.errors.full_messages.uniq]
        end
      end
    end
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
    @activity_type = {}
    @company.company_activity_types.each {|at| @activity_type[at.alvalue]=at.id}
    @hash_records.each_with_index do |record,index|
      flag = false
      
      if record["time_entry_date"].blank?
        record["errors"] << "Date can not be blank"
        flag = true
      else
        time_entry_date = Date.parse(record["time_entry_date"]).strftime("%Y-%m-%d")
        record["time_entry_date"] = time_entry_date
      end


      if !record["employee_user_id"].nil? && !record["employee_user_id"].empty?
        assigned_to = User.find_by_sql("SELECT * FROM employees WHERE ((trim(employees.first_name) || ' ' || trim(employees.last_name) iLike '#{record["employee_user_id"]}') ) AND company_id = #{@company.id} LIMIT 1")
     
		    if assigned_to.empty?
          record["errors"] << "Invalid Employee name"
          flag = true
			  else
				  record["employee_user_id"] = assigned_to.first.user_id
			  end
      else
        record["errors"] << " Name of employee does not exist."
        flag = true
      end

      if record["matter_no"].present? && record["name"].present? && !record["time_entry_date"].blank?
        matter_no = set_matter_no(record["matter_no"])
        record["matter_no"] = matter_no
        matter = @company.matters.find_by_matter_no_and_name(matter_no,record["name"])
        @matter_inception_date = Date.parse(matter.matter_date.to_s).strftime("%Y-%m-%d") if matter.present?
        if !matter.blank?
          record["matter_id"] = matter.id
        else
           record["errors"] << " Invalid Matter No. or Name  "
           flag = true
        end
        date_check = (time_entry_date >= @matter_inception_date) if @matter_inception_date.present?
        if !(date_check) && !matter.blank? && !@matter_inception_date.blank?
           record["errors"] << " Date should be grater than inception date of matter  "
           flag = true
        end
      elsif record["matter_no"].blank?
        record["errors"] << " Matter No. can not be blank  "
        flag = true
      elsif record["name"].blank?
        record["errors"] << " Matter Name can not be blank  "
        flag = true
      end

      if record["first_name"].present?
        contact_name = record["first_name"].strip
        c_condition = "trim(first_name)"
        if record["middle_name"].present?
          contact_name = contact_name + ' ' + record["middle_name"].strip
          c_condition += " || ' ' || trim(middle_name)"
        end
        if record["last_name"].present?
          contact_name = contact_name + ' ' + record["last_name"].strip
          c_condition += " || ' ' || trim(last_name)"
        end
        if !record["first_name"] and matter.present?
          record["errors"] << " Contact name can not be blank for matter.  "
          flag = true
        end
      else
        record["errors"] << " Contact first name can not be blank.  "
        flag = true
      end

      matter_contact = @company.contacts.find(:all, :conditions => ["("+ c_condition +") ilike ? ", contact_name]) if record["first_name"].present? && matter.present?

      if matter_contact.blank?
        record["errors"] << " Contact is not linked to matter "
        flag = true
      end
      
  
      # for managing activity_type id by default is lead id
      if !record["activity_type"].nil? && !record["activity_type"].empty?
        if @activity_type.keys.include?(record["activity_type"])
          record["activity_type"] = @activity_type[record["activity_type"]]
        else
          record["errors"] << "Invalid Activity Type"
          flag = true
        end
      else
        record["errors"] << "Activity Type can not blank ."
        flag = true
      end

      if record["description"].blank?
        record["errors"] << "Description can not be blank"
        flag = true
      else
        record["description"] = record["description"]
      end

      if record["actual_duration"].blank?
        record["errors"] << "Duration can not be blank"
        flag = true
      else
        record["actual_duration"] = record["actual_duration"].to_f * 60.0
      end

      if record["actual_activity_rate"].blank?
        record["errors"] << "Rate can not be blank"
        flag = true
      else
        record["actual_activity_rate"] = record["actual_activity_rate"]
      end

      record["final_billed_amount"] = record["final_billed_amount"].blank? ? '' :  record["final_billed_amount"]

      if flag
        @invalid_records <<['',@roo_object.row(index+1+@first_row),record["errors"].join(",")]
      else
        time_entry_info = parse_time_entry_details(record,@company.id)
        @object_records <<  [Physical::Timeandexpenses::TimeEntry.new(time_entry_info),index]
      end
    end

    import_object_record
    invalid_records_to_excel(@error_path,@invalid_records,["Error",EXCEL_HEADERS].flatten)
  end

  def set_matter_no(val)
    if val.nil? || val.empty?
      val=nil
    else
      val.to_s.gsub('.0', '''').to_s
    end
  end

  def parse_time_entry_details(record,company_id)
    time_entry_info= {}
    TIME_ENTRY_DETAILS.each do |te|
      time_entry_info[te] = record[te]
    end
    #  contact_info["status_type"] = ''
    time_entry_info["company_id"] = company_id
    time_entry_info
  end

end
