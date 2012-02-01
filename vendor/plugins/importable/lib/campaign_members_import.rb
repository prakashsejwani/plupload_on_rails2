class CampaignMembersImport < ExcelImport
  attr_accessor :employee_user_id,:company_id,:current_user_id,:header_array,:error_path,:campaign_id

  CAMPAIGN_MEMBERS_DETAILS =
    ["salutation_id", "first_name", "last_name", "nickname" ,"email","alt_email","phone", "mobile","fax","website" ,"title"]

  ADDRESS_DETAILS = ["street", "city", "state", "country", "zipcode","country"]
  HEADERS = ["salutation_id","first_name","last_name","nick_name","email","alt_email","phone","mobile","fax","website","title","street","city","state","zipcode","country"]

  EXCEL_HEADERS= ["Salutation","*First Name","Last Name","Nick Name","#Primary Email","Alternate Email","#Primary Phone","Mobile","Fax","Website","Title","Street","City","State","Zip Code","Country"]

  def initialize(current_user_id,employee_user_id,company_id,campaign_id,error_path,file_path=nil,options={})
    @current_user_id,@employee_user_id,@company_id,@campaign_id = current_user_id,employee_user_id,company_id,campaign_id
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
    ActiveRecord::Base.transaction do
      @object_records.each do |object|
        campaign_member = CampaignMember.new(object[0])
        address = campaign_member.build_address(object[1])
        index = object[2]
        if campaign_member.valid?
          begin
            if campaign_member.save
              @valid_records << [campaign_member,@roo_object.row(index+1+@first_row)]
            else
              @invalid_records << [campaign_member,@roo_object.row(index+1+@first_row),campaign_member.errors.full_messages.uniq]
            end
          rescue
            @invalid_records << [campaign_member,@roo_object.row(index+1+@first_row),campaign_member.errors.full_messages.uniq]
          end
        else
          @invalid_records << [campaign_member,@roo_object.row(index+1+@first_row),campaign_member.errors.full_messages.uniq]
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
    @campaign = Campaign.find(@campaign_id)
    #owner_employee_user = @campaign.owner_employee_user_id.blank? ? @current_user : Employee.find_by_user_id(@campaign.owner_employee_user_id)
    @salutation = {}
    @company.salutation_types.each {|st| @salutation[check_salutation(st.alvalue)] = st.id}
    @default_campaign_member_status = @company.campaign_member_status_types.find_by_lvalue('New').try(:id)
    @hash_records.each_with_index do |record,index|
      flag = false
      # if assigned to is present find out user id from employees table based on first name or last name
      record["phone"] = set_phone_no(record["phone"])
      record["mobile"] = set_phone_no(record["mobile"])

      if !record["salutation_id"].nil? && !record["salutation_id"].empty?
        salutation = check_salutation(record["salutation_id"])
        if @salutation.keys.include?(salutation)
          record["salutation_id"] = @salutation[record["salutation_id"]]
        else
          record["errors"] << "Invalid Salutation."
          flag = true
        end
      end
      if flag
        @invalid_records <<['',@roo_object.row(index+1+@first_row),record["errors"]]
      else
        campaign_members_info = parse_campaign_members_details(record,@company.id,@default_campaign_member_status)
        address_details = parse_address_details(record,@company.id)
        @object_records <<  [campaign_members_info,(address_details),index]
      end   
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
  
  # this function is to compare cases like MR  & MR. from user and database respectively as these are valid
  def check_salutation(value)
    value.downcase.gsub(/[\W+]/,' ').strip
  end


  def parse_campaign_members_details(record,company_id,default_campaign_member_status)
    campaign_members_info= {}
    CAMPAIGN_MEMBERS_DETAILS.each do |cd|
      campaign_members_info[cd] = record[cd]
    end
    campaign_members_info["company_id"] = company_id
    campaign_members_info["created_by_user_id"] = @current_user_id
    campaign_members_info["employee_user_id"] = @employee_user_id
    campaign_members_info["campaign_id"] = @campaign_id
    campaign_members_info["campaign_member_status_type_id"] = default_campaign_member_status
    campaign_members_info
  end

  def parse_address_details(record,company_id)
    address_details =  {}
    ADDRESS_DETAILS.each do |ad|
      address_details[ad]= record[ad]
    end
    address_details["company_id"] = company_id
    address_details
  end

end

