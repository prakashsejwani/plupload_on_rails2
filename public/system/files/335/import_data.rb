module ImportData
  require 'flexible_csv'
  require 'csv'
  require 'spreadsheet'
  include GeneralFunction


  def self.contact_process_excel_file(file_name,file,company,user,employee_user)
    unless file.blank?
      # Below code is use to parse cvs file.
      #BEGIN
      name = file_name
      directory =  "#{RAILS_ROOT}/assets/"
      path = File.join(directory, name)
      File.open(path, "wb") { |f| f.write(file) }
      ext = File.extname(name)
      if ext==".xls"
        oo= Excel.new(path)
      elsif ext==".xlsx"
        oo= Excelx.new(path)
      elsif ext==".ods"
        oo = Openoffice.new(path)
      end

      #oo= Excel.new(path)
      oo.default_sheet = oo.sheets.first
     
      @assigned_to =[]
      @company=company
      @invalid_length=0
      @valid_length=0
      @invalid_contacts=[]
      @current_user=user
      @employee_user_id=employee_user.id
      @cell_str_s = []
      4.upto(oo.last_row) do |line|
        self.contacts_excel_parsing(oo,line)
      end
      report = Spreadsheet::Workbook.new
        sheet = report.create_worksheet
        sheet.row(0).concat ['Salutation','First Name','Last Name','Primary Email','Primary Phone','Nick name','Alertnate Email','Source','Assigned To','Company','Title','Street','City','State','Zip Code','Fax','Alternate Phone 1','Alternate Phone 2','Website','Street','City','State','Zip Code','Mobile','Fax','Skype Account','Linked In Account','Facebook Account','Twitter Account','','Error Description' others1.to_s, others2.to_s, others3.to_s, others4.to_s, others5.to_s, others6.to_s,department.to_s, preference.to_s, country.to_s, status_type.to_s ]


        @invalid_contacts.each_with_index do |invalid_contacts, j|
           sheet.row(j+1).concat invalid_contacts
        end
        @xls_string_errors = StringIO.new ''
        report.write @xls_string_errors
      begin
        err_directory = "public/"
        err_filename="invalid_contacts_report_#{Time.now}.xls"
        err_path = File.join(err_directory,err_filename)
        File.open(err_path, "wb") { |f| f.write(@xls_string.string) }
        send_notification_for_invalid_contacts(err_path,@current_user,@invalid_length,@valid_length,employee_user)
        File.delete("#{RAILS_ROOT}/public/#{err_filename}")
        File.delete("#{RAILS_ROOT}/assets/#{file_name}")
      rescue Exception=>ex
        #send notification for any failure
        puts ex.message
      end

    end
  end

  def self.contact_process_file(file_name,file,company,user,employee_user)
    unless file.blank?
      # Below code is use to parse cvs file.
      name = file_name
      directory =  "#{RAILS_ROOT}/assets/"
      path = File.join(directory, name)
      File.open(path, "wb") { |f| f.write(file) }

      @parser = CSV::Reader.parse(file)
      @assigned_to =[]
      @company=company
      @invalid_length=0
      @valid_length=0
      @invalid_contacts=[]
      @current_user=user
      @employee_user_id=employee_user.id
      
      # Below code is use to fetch each parse data.
      @parser.each_with_index do |column,i|
        self.contacts_parsing(column,i)
      end
      File.delete("#{RAILS_ROOT}/assets/#{file_name}")

      begin
        directory = "public/"
        filename="invalid_contacts_report_#{Time.now}.csv"
        path = File.join(directory,filename)
        File.open(path, "wb") { |f| f.write(@csv_string) }
        send_notification_for_invalid_contacts(path,@current_user,@invalid_length,@valid_length,employee_user)
        File.delete("#{RAILS_ROOT}/public/#{filename}")
      rescue Exception=>ex
        #send notification for any failure
        puts ex.message
      end
    end
  end

  def self.contacts_excel_parsing(oo,line)
    #    begin
    comments_details = oo.cell(line,'AJ').blank?? "Imported from file." : "#{oo.cell(line,'AJ')}:Imported from file."

    #NOTE:
    #Arrangement of column is done according to the sequence
    #----------------COLUMN START---------------------


          #********************************************************************************************
      #****************************** Modified By Sumanta Das *************************************
      #********************************************************************************************

      # This below line of code is for adding salutaion_id into contacts table while importing contacts--Rahul P 5/5/2011

      unless oo.cell(line,'A').blank?
        cell_str = oo.cell(line,'A').try(:capitalize)
        salutation = @company.salutation_types.find_by_lvalue_and_company_id(cell_str, @comapny.id).present? ? @company.salutation_types.find_by_lvalue_and_company_id(cell_str, @comapny.id).id : 0 #.find_by_lvalue(cell_str).id : 0   ####.find_by_lvalue(cell_str)
        #salutation = @company.salutation_types.find_by_lvalue(cell_str).id
      else
        salutation = 0
      end
      if oo.cell(line,'B').present? && oo.cell(line,'B').to_s.include?("'")
     		first_name =  oo.cell(line,'B').to_s.gsub(/[']/, '''')
      else
        first_name =  oo.cell(line,'B').to_s
      end
      if oo.cell(line,'C').present? && oo.cell(line,'C').to_s.include?("'")
     		last_name  =  oo.cell(line,'C').to_s.gsub(/[']/, '''')
      else
        last_name  =  oo.cell(line,'C').to_s
      end

      if oo.cell(line,'D').present? && oo.cell(line,'D').to_s.include?("'")
     		email  =  oo.cell(line,'D').to_s.gsub(/[']/, '''')
      else
        email  =  oo.cell(line,'D').to_s
      end

      if oo.cell(line,'E').present? && oo.cell(line,'E').to_s.include?("'")
     		phone  =  oo.cell(line,'E').to_s.gsub(/[']/, '''')
      else
        phone  =  oo.cell(line,'E').to_s
      end

      if oo.cell(line,'F').present? && oo.cell(line,'F').to_s.include?("'")
     		nick_name  =  oo.cell(line,'F').to_s.gsub(/[']/, '''')
      else
        nick_name  =  oo.cell(line,'F').to_s
      end

      if oo.cell(line,'G').present? && oo.cell(line,'G').to_s.include?("'")
     		alt_email  =  oo.cell(line,'G').to_s.gsub(/[']/, '''')
      else
        alt_email  =  oo.cell(line,'G').to_s
      end

      @cell_str_s << oo.cell(line,'H').try(:capitalize)
      if oo.cell(line,'H').present?
        cell_str_s = oo.cell(line,'H').try(:capitalize)
        lookup_lead_source = @company.company_sources.find_by_lvalue_and_company_id(cell_str_s, @comapny.id)#.find_by_lvalue(cell_str_s)#.id
        #salutation = salutation_check.blank? ? '' : salutation_check.id
        if lookup_lead_source.nil?
          lookup_lead_source = @company.company_sources.find_by_lvalue_and_company_id('Other', @comapny.id)#.find_by_lvalue('Other')
        end
      else
        lookup_lead_source = @company.company_sources.find_by_lvalue_and_company_id('Other', @comapny.id)#.find_by_lvalue('Other')
      end

      #Add few required fields details Assigned Lawyers id.
      assigned_false = false
      unless  oo.cell(line,'I').nil?
        name = oo.cell(line,'I').split(' ')
        uname = "#{oo.cell(line,'I').strip}"
        employee_details = User.find(:first, :conditions =>["trim(first_name) || ' ' || trim(last_name) = ? and company_id = ?", uname,@company.id])
        #employee_details = User.find_by_first_name_and_last_name_and_company_id(name[0],name[1],@company.id)
        if employee_details.nil?
         assigned_false = true
         assigned_to = @current_user.id
        else
         assigned_to = employee_details.id
        end
      else
        assigned_to = @current_user.id
      end

      if oo.cell(line,'J').present? && oo.cell(line,'J').to_s.include?("'")
     		organisation  =  oo.cell(line,'J').to_s.gsub(/[']/, '''')
      else
        organisation =  oo.cell(line,'J').to_s
      end

      if oo.cell(line,'K').present? && oo.cell(line,'K').to_s.include?("'")
     		title  =  oo.cell(line,'K').to_s.gsub(/[']/, '''')
      else
        title  =  oo.cell(line,'K').to_s
      end

      if oo.cell(line,'L').present? && oo.cell(line,'L').to_s.include?("'")
     		business_street  =  oo.cell(line,'L').to_s.gsub(/[']/, '''')
      else
        business_street  =  oo.cell(line,'L').to_s
      end

      if oo.cell(line,'M').present? && oo.cell(line,'M').to_s.include?("'")
     		business_city  =  oo.cell(line,'M').to_s.gsub(/[']/, '''')
      else
        business_city  =  oo.cell(line,'M').to_s
      end

      if oo.cell(line,'N').present? && oo.cell(line,'N').to_s.include?("'")
     		business_state  =  oo.cell(line,'N').to_s.gsub(/[']/, '''')
      else
        business_state  =  oo.cell(line,'N').to_s
      end


      if oo.cell(line,'O').present?
       # business_postal_code =oo.cell(line,'O')
        if oo.cell(line,'O').present? && oo.cell(line,'O').to_s.include?("'")
          business_postal_code = oo.cell(line,'O').to_s.gsub(/[']/, '''')
        else
          business_postal_code = oo.cell(line,'O').to_s
        end
        begin
          if business_postal_code.to_i>0
            business_postal_code = business_postal_code.floor
          else
            business_postal_code =business_postal_code.to_s
          end
        rescue
        end
      end

          if oo.cell(line,'P').present?
       # business_postal_code =oo.cell(line,'O')
        if oo.cell(line,'P').present? && oo.cell(line,'P').to_s.include?("'")
          business_fax = oo.cell(line,'P').to_s.gsub(/[']/, '''')
        else
          business_fax = oo.cell(line,'P').to_s
        end
        begin
          if business_fax.to_i>0
            business_fax = business_fax.floor
          else
            business_fax = business_fax.to_s
          end
        rescue
        end
      end

      if oo.cell(line,'Q').present?
        if oo.cell(line,'Q').present? && oo.cell(line,'Q').to_s.include?("'")
          business_phone  =  oo.cell(line,'Q').to_s.gsub(/[']/, '''')
        else
          business_phone  =  oo.cell(line,'Q').to_s
        end
        #business_phone =oo.cell(line,'Q')
        begin
          if business_phone.to_i>0
            business_phone = business_phone.floor
          else
            business_phone = business_phone.to_s
          end
        rescue
        end
      end


      if oo.cell(line,'R').present?
        if oo.cell(line,'R').present? && oo.cell(line,'R').to_s.include?("'")
          businessphone2  =  oo.cell(line,'R').to_s.gsub(/[']/, '''')
        else
           businessphone2  =  oo.cell(line,'R').to_s
        end
        #businessphone2 = oo.cell(line,'R')
        begin
          if businessphone2.to_i>0
            businessphone2 = businessphone2.floor
          else
            if  businessphone2.to_s.length > 32
             businessphone2 = businessphone2.slice!(15..-1)
            else
             businessphone2 = businessphone2.to_s
            end
          end
        rescue
        end
      end

      if oo.cell(line,'S').present? && oo.cell(line,'S').to_s.include?("'")
     		website  =  oo.cell(line,'S').to_s.gsub(/[']/, '''')
      else
        website  =  oo.cell(line,'S').to_s
      end

      if oo.cell(line,'T').present? && oo.cell(line,'T').to_s.include?("'")
     		street  =  oo.cell(line,'T').to_s.gsub(/[']/, '''')
      else
        street  =  oo.cell(line,'T').to_s
      end

      if oo.cell(line,'U').present? && oo.cell(line,'U').to_s.include?("'")
     		city  =  oo.cell(line,'U').to_s.gsub(/[']/, '''')
      else
        city  =  oo.cell(line,'U').to_s
      end

      if oo.cell(line,'V').present? && oo.cell(line,'V').to_s.include?("'")
     		state  =  oo.cell(line,'V').to_s.gsub(/[']/, '''')
      else
        state  =  oo.cell(line,'V').to_s
      end

      if oo.cell(line,'W').present?
        if oo.cell(line,'W').present? && oo.cell(line,'W').to_s.include?("'")
          zip_code  =  oo.cell(line,'W').to_s.gsub(/[']/, '''')
        else
          zip_code  =  oo.cell(line,'W').to_s
        end
        #zip_code =oo.cell(line,'W')
        begin
          if zip_code.to_i>0
            zip_code = zip_code.floor
          else
            zip_code = zip_code.to_s
          end
        rescue
        end
      end

      if oo.cell(line,'X').present? && oo.cell(line,'X').to_s.include?("'")
     		mobile  =  oo.cell(line,'X').to_s.gsub(/[']/, '''')
      else
        mobile  =  oo.cell(line,'X').to_s
      end

      if oo.cell(line,'Y').present? && oo.cell(line,'Y').to_s.include?("'")
     		fax  =  oo.cell(line,'Y').to_s.gsub(/[']/, '''')
      else
        fax  =  oo.cell(line,'Y').to_s
      end
     # fax = oo.cell(line,'Y').to_s if oo.cell(line,'Y').present?



      if oo.cell(line,'Z').present? && oo.cell(line,'Z').to_s.include?("'")
     		skype_account  =  oo.cell(line,'Z').to_s.gsub(/[']/, '''')
      else
        skype_account  =  oo.cell(line,'Z').to_s
      end

      if oo.cell(line,'AA').present? && oo.cell(line,'AA').to_s.include?("'")
     		linked_in_account  =  oo.cell(line,'AA').to_s.gsub(/[']/, '''')
      else
        linked_in_account  =  oo.cell(line,'AA').to_s
      end

      if oo.cell(line,'AB').present? && oo.cell(line,'AB').to_s.include?("'")
     		facebook_account  =  oo.cell(line,'AB').to_s.gsub(/[']/, '''')
      else
        facebook_account  =  oo.cell(line,'AB').to_s
      end

      if oo.cell(line,'AC').present? && oo.cell(line,'AC').to_s.include?("'")
     		twitter_account  =  oo.cell(line,'AC').to_s.gsub(/[']/, '''')
      else
        twitter_account  =  oo.cell(line,'AC').to_s
      end

      if oo.cell(line,'AK').present? && oo.cell(line,'AK').to_s.include?("'")
     		department  =  oo.cell(line,'AK').to_s.gsub(/[']/, '''')
      else
        department  =  oo.cell(line,'AK').to_s
      end

      if oo.cell(line,'AL').present? && oo.cell(line,'AL').to_s.include?("'")
     		preference  =  oo.cell(line,'AL').to_s.gsub(/[']/, '''')
      else
        preference  =  oo.cell(line,'AL').to_s
      end

      if oo.cell(line,'AM').present? && oo.cell(line,'AM').to_s.include?("'")
     		business_country  =  oo.cell(line,'AM').to_s.gsub(/[']/, '''')
      else
        business_country  =  oo.cell(line,'AM').to_s
      end

      if oo.cell(line,'AN').present? && oo.cell(line,'AN').to_s.include?("'")
     		country  =  oo.cell(line,'AN').to_s.gsub(/[']/, '''')
      else
        country  =  oo.cell(line,'AN').to_s
      end

      unless oo.cell(line,'AR').blank?
        cell_str = oo.cell(line,'AR').try(:capitalize)
        contact_stage_id = @company.contact_stages.array_to_hash('lvalue')[cell_str].id
        if cell_str == "Lead"
          status_type_id = LeadStatusType.find_by_lvalue_and_company_id('New', @comapny.id).id#.find_by_lvalue('New').id
        else
          status_type_id = ProspectStatusType.find_by_lvalue_and_company_id('Active', @comapny.id).id #.find_by_lvalue('Active').id
        end
#		      status_details ={:contact_stage_id=> contact_stage.id,:status_type=>status_typ_id}
      else
        contact_stage_id = @company.contact_stages.array_hash_value('lvalue','Lead','id')
        status_type_id = LeadStatusType.find_by_lvalue_and_company_id('New', @comapny.id).id #.find_by_lvalue("New").id
#		      status_details ={:contact_stage_id=> contact_stage_id,:status_type=>status_type_id}
      end

      #********************************************************************************************
      #**************************** End Of Modification :- Sumanta Das ****************************
      #********************************************************************************************



#      unless oo.cell(line,'A').blank?
#      cell_str = oo.cell(line,'A').try(:capitalize)
#      salutation_check = @company.salutation_types.find_by_lvalue(cell_str)#.id
#      salutation = salutation_check.blank? ? '' : salutation_check.id
#      salutation = @company.salutation_types.find_by_lvalue(cell_str).id
#    end
#    first_name=oo.cell(line,'B').to_s
#    middle_name=oo.cell(line,'C').to_s
#    last_name=oo.cell(line,'D').to_s
#
#
#    if oo.cell(line,'E').present?
#      email=oo.cell(line,'E')
#    end
#    email=email.to_s
#
#    if oo.cell(line,'F').present?
#      phone=oo.cell(line,'F')
#      begin
#        if oo.cell(line,'F').to_i>0
#          phone= oo.cell(line,'F').floor
#        else
#          phone = oo.cell(line,'F').to_s
#        end
#      rescue
#      end
#    end
#    phone=phone.to_s
#    nickname=oo.cell(line,'G')
#    alt_email=oo.cell(line,'H')
#    source=oo.cell(line,'I')
#    source_details=oo.cell(line,'J')
#    assigned_to_employee_user_id=oo.cell(line,'K')
#    organization=oo.cell(line,'L')
#    title=oo.cell(line,'M')
#    business_street=oo.cell(line,'N')
#    business_city=oo.cell(line,'O')
#    business_state=oo.cell(line,'P')
#    if oo.cell(line,'Q').present?
#      business_postal_code =oo.cell(line,'Q')
#      begin
#        if oo.cell(line,'Q').to_i>0
#          business_postal_code = oo.cell(line,'Q').floor
#        else
#          business_postal_code =oo.cell(line,'Q')
#        end
#      rescue
#      end
#    end
#
#    business_fax = oo.cell(line,'R').to_s
#    if business_fax.include? "-"  or business_fax.include? "+"
#      business_fax = oo.cell(line,'R')
#    else
#      business_fax = (oo.cell(line,'R')).to_i if business_fax.present?
#    end
#
#    if oo.cell(line,'S').present?
#      business_phone =oo.cell(line,'S')
#      begin
#        if oo.cell(line,'S').to_i>0
#          business_phone = oo.cell(line,'S').floor
#        else
#          business_phone =oo.cell(line,'S')
#        end
#      rescue
#      end
#    end
#    if oo.cell(line,'T').present?
#      businessphone2 =oo.cell(line,'T')
#      begin
#        if oo.cell(line,'T').to_i>0
#          businessphone2 = oo.cell(line,'T').floor
#        else
#          businessphone2 =oo.cell(line,'T')
#        end
#      rescue
#      end
#    end
#    website=oo.cell(line,'U')
#    street=oo.cell(line,'V')
#    city=oo.cell(line,'W')
#    state=oo.cell(line,'X')
#    if oo.cell(line,'Y').present?
#      zip_code =oo.cell(line,'Y')
#      begin
#        if oo.cell(line,'Y').to_i>0
#          zip_code = oo.cell(line,'Y').floor
#        else
#          zip_code =oo.cell(line,'Y')
#        end
#      rescue
#      end
#    end
#    if oo.cell(line,'Z').present?
#      mobile=oo.cell(line,'Z')
#      begin
#        if oo.cell(line,'Z').to_i>0
#          mobile= oo.cell(line,'Z').floor
#        else
#          mobile=oo.cell(line,'Z')
#        end
#      rescue
#      end
#    end
#    mobile=mobile.to_s
#
#    fax = oo.cell(line,'AA').to_s
#    if fax.include? "-"  or fax.include? "+"
#      fax = oo.cell(line,'AA')
#    else
#      fax = (oo.cell(line,'AA')).to_i if fax.present?
#    end
#    fax=fax
#
#    skype_account=oo.cell(line,'AB')
#
#    linked_in_account=oo.cell(line,'AC')
#    facebook_account=oo.cell(line,'AD')
#    twitter_account=oo.cell(line,'AE')
    others1=oo.cell(line,'AF')
    others2=oo.cell(line,'AG')
    others3=oo.cell(line,'AH')
    others4=oo.cell(line,'AI')
    others5=oo.cell(line,'AJ')
    others6=oo.cell(line,'AK')
    department=oo.cell(line,'AL')
    preference=oo.cell(line,'AM')
    country=oo.cell(line,'AN')
    unless oo.cell(line,'AR').blank?
      status_type = oo.cell(line,'AR').try(:capitalize)
    end
   #---------------------COLUMN NUMBER END-----------------







		      # Below code gives status details depending on status type [Lead,Prospect,Client].
		    # Will add this hash in @contact_details hash.

       if self.valid?(oo, line, assigned_false)

        ActiveRecord::Base.connection.execute("SELECT setval('contacts_id_seq', (select max(id) + 1 from contacts));")

		    @contact = Contact.find_by_sql("INSERT INTO contacts(assigned_to_employee_user_id, first_name, last_name, title, organization, source, email, alt_email, phone, mobile, website, status_type, department, fax, preference, nickname, company_id, created_by_user_id, salutation_id, created_at, updated_at)
	VALUES (#{assigned_to}, '#{first_name.to_s}', '#{last_name.to_s}', '#{title}', '#{organisation}', #{lookup_lead_source.id}, '#{email.to_s}', '#{alt_email.to_s}', '#{phone.to_s}', '#{mobile}', '#{website}' , '#{status_type_id}', '#{department}','#{fax}', '#{preference}', '#{nick_name.to_s}', #{@company.id}, #{@employee_user_id}, #{(salutation)}, '#{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')}', '#{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')}') RETURNING id;")



#       @contact = Contact.find_by_sql("SELECT * FROM contacts WHERE first_name = '#{first_name}' AND last_name = '#{last_name}' AND email = '#{email}' AND phone = '#{phone}' AND company_id = #{@company.id}")
       @contact.each do |c|
         @contact_id = c.id
       end

      ActiveRecord::Base.connection.execute("SELECT setval('addresses_id_seq', (select max(id) + 1 from addresses));")

       ActiveRecord::Base.connection.execute("INSERT INTO addresses(street, city, country, zipcode, state, contact_id, company_id) VALUES ('#{oo.cell(line,'T').present? ? street : ''}', '#{oo.cell(line,'U').present? ? city : ''}', '#{oo.cell(line,'AN').present? ? country : ''}', '#{zip_code}', '#{oo.cell(line,'V').present? ? state : ''}', #{@contact_id}, #{@company.id});")

ActiveRecord::Base.connection.execute("SELECT setval('contact_additional_fields_id_seq', (select max(id) + 1 from contact_additional_fields));")

       	ActiveRecord::Base.connection.execute("INSERT INTO contact_additional_fields(business_street, business_city, business_state,business_country, business_postal_code, business_fax, business_phone, businessphone2, linked_in_account, twitter_account, facebook_account, skype_account, contact_id, company_id) VALUES
('#{oo.cell(line,'L').present? ? business_street.slice!(0..63) : ''}', '#{oo.cell(line,'M').present? ? business_city.slice!(0..63) : ''}', '#{oo.cell(line,'N').present? ? business_state.slice!(0..63) : ''}','#{oo.cell(line,'AM').present? ? business_country.slice!(0..63) : ''}', '#{business_postal_code}', '#{business_fax}', '#{oo.cell(line,'Q').present? ? business_phone.slice!(0..15) : ''}', '#{oo.cell(line,'R').present? ? businessphone2.slice!(0..15) : ''}', '#{oo.cell(line,'AA').present? ? linked_in_account.slice!(0..63) : ''}', '#{oo.cell(line,'AC').present? ? twitter_account.slice!(0..63) : ''}', '#{oo.cell(line,'AB').blank? ? facebook_account.slice!(0..63) : ''}','#{oo.cell(line,'Z').present? ? skype_account.slice!(0..63) : ''}',  #{@contact_id}, #{@company.id});")


       else
         error_message = first_name.blank? ? "Contact First Name can't be Blank " : ""
         error_message += !assigned_false ?  "Assigned To Is Invalid " : ""
         error_message += oo.cell(line,'B').to_s.length > 64 ? "Contact First Name should not be more than 64 characters  " : ""
         error_message += oo.cell(line,'C').to_s.length > 64 ? "Contact Last Name should not be more than 64 characters  " : ""
         error_message += oo.cell(line,'F').to_s.length > 64 ? "Contact Nick Name should not be more than 64 characters " : ""
				 error_message += oo.cell(line,'E').to_s.length > 15 ? "Contact Phone Number should not be more than 15 digits  " : ""
         error_message += oo.cell(line,'D').to_s.length > 64 ? "Contact Email should not be more than 64 characters " : ""
				 error_message += oo.cell(line,'X').to_s.length > 15 ? "Contact Mobile Number should not be more than 15 characters  " : ""
				 error_message += oo.cell(line,'Y').to_s.length > 15 ? "Contact Fax should not be more than 15 numbers " : ""
         error_message += oo.cell(line,'D') =~ /^(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6}$/ ? "" : "Contact Email is Invalid "
         error_message += oo.cell(line,'P') =~ /^[+\/\-()# 0-9]+$/ ? "" : "Contact Business Fax Invalid "


				@invalid_contacts << [(salutation).to_s,first_name.to_s,last_name.to_s,email.to_s, phone,
          nick_name.to_s, alt_email.to_s, oo.cell(line,'H'), oo.cell(line,'I').to_s, organisation.to_s,
          title.to_s, business_street.to_s, business_city.to_s, business_state.to_s, business_postal_code.to_s,
          business_fax.to_s, business_phone.to_s, businessphone2.to_s, website.to_s, street.to_s, city.to_s,
          state.to_s, zip_code.to_s, mobile.to_s, fax.to_s, skype_account.to_s, twitter_account.to_s, '',
          error_message.to_s others1.to_s, others2.to_s, others3.to_s, others4.to_s, others5.to_s, others6.to_s,
          department.to_s, preference.to_s, country.to_s, status_type.to_s ]
      end

  end



def self.valid?(oo, line, assigned_false)
	if oo.cell(line,'B').present? && (oo.cell(line,'D').present? || oo.cell(line,'E').present?) #1
    return true
    puts "=--------------------=first_name and (email or phone)---------------ok"
  else
    return false
    break
  end


		if oo.cell(line,'B').to_s.length <= 64 && oo.cell(line,'C').to_s.length <= 64 && oo.cell(line,'D').to_s.length <= 64 && oo.cell(line,'E').to_s.length <= 15 && oo.cell(line,'F').to_i.length <= 15 && oo.cell(line,'X').to_i.length <= 15 && oo.cell(line,'Y').to_i.length <= 15  #2

          puts "=--------------------=Length---------------ok"
      return true
    else
      return false
      break
    end

	    if oo.cell(line,'D').present? && oo.cell(line,'D') =~ /^(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6}$/

            puts "=--------------------=Email valid---------------ok"
           return true
	      else
	        return false
          break
	    end
			if oo.cell(line,'P').present? && oo.cell(line,'P') =~ /^[+\/\-()# 0-9]+$/

           puts "=--------------------=Business Fax Valid---------------ok"
           return true
	      else
	        return false
          break
	    end
      if !assigned_false

         puts "=--------------------=Assigned_false---------------ok"
         return true
      else
        return false
        break
      end

end




  def self.contacts_parsing(column,i)
    if i >= 3
      comments_details = column[36].blank?? "Imported from file." : "#{column[36]}:Imported from file."
      # This below line of code is for adding salutaion_id into contacts table while importing contacts--Rahul P 5/5/2011
      unless column[0].blank?
        cell_str = column[0].try(:capitalize)
        salutation_check = @company.salutation_types.find_by_lvalue_and_company_id(cell_str, @comapny.id) #find_by_lvalue(cell_str)
        salutation = salutation_check.blank? ? '' : salutation_check.id
      end
      first_name = column[1].to_s
      middle_name = column[2]
      last_name = column[3]
      email = column[4]
      phone = column[5]
      nick_name = column[6]
      alt_email = column[7]
      source = column[8]
      source_detail = column[9].blank? ? '' : column[9]
      assigned_to = column[10]
      company = column[11]
      title = column[12]
      b_street = column[13].blank? ? '' : column[13]
      b_city = column[14].blank? ? ''  : column[14]
      b_state = column[15].blank? ? ''  : column[15]
      b_zip_code = column[16].blank? ? ''  : column[16]
      b_fax = column[17].blank? ? ''  : column[17]
      alt_phone_1 = column[18].blank? ? ''  : column[18]
      alt_phone_2 = column[19].blank? ? ''  : column[19]
      website = column[20].blank? ? ''  : column[20]
      p_street = column[21].blank? ? ''  : column[21]
      p_city = column[22].blank? ? ''  : column[22]
      p_state = column[23].blank? ? ''  : column[23]
      p_zip_code = column[24].blank? ? ''  : column[24]
      mobile = column[25].blank? ? ''  : column[25]
      p_fax = column[26].blank? ? ''  : column[26]
      skype = column[27].blank? ? ''  : column[27]
      linked = column[28].blank? ? ''  : column[28]
      facebook = column[29].blank? ? ''  : column[29]
      twitter = column[30].blank? ? ''  : column[30]
      others_1 = column[31].blank? ? ''  : column[31]
      others_2 = column[32].blank? ? ''  : column[32]
      others_3 = column[33].blank? ? ''  : column[33]
      others_4 = column[34].blank? ? ''  : column[34]
      others_5 = column[35].blank? ? ''  : column[35]
      others_6 = column[36].blank? ? ''  : column[36]
      department = column[37].blank? ? ''  : column[37]
      preference = column[38].blank? ? ''  : column[38]
      # Below code will create a new hash with mandatory fields [first_name,last_name,email,phone] and othere fields [topic,notes,user_id].
      @contact_details ={"salutation_id"=>salutation.to_s,"first_name"=>first_name,"middle_name"=> middle_name,"last_name"=>last_name,"nickname"=>nick_name,"email"=>email,"phone"=>phone,"mobile"=>mobile,"fax"=>p_fax,"website"=>website,"title"=>title,"assigned_to_employee_user_id" => assigned_to ,"department"=>department,"alt_email"=>alt_email,"preference"=>preference,"organization"=>company,"created_by_user_id" => @employee_user_id,:user_comment=>comments_details,"source_details" => source_detail}
      #      @contact_details ={"salutation"=>oo.cell(line,'A').to_s,"first_name"=>oo.cell(line,'B').to_s,"last_name"=>oo.cell(line,'C').to_s,"nickname"=>oo.cell(line,'F'),"email"=>email.to_s,"phone"=>phone.to_s,"mobile"=>mobile.to_s,"fax"=>fax,"website"=>oo.cell(line,'R'),"title"=>oo.cell(line,'J'),"assigned_to_employee_user_id"=>oo.cell(line,'H'),"department"=>oo.cell(line,'AK'),"alt_email"=>oo.cell(line,'G'),"preference"=>oo.cell(line,'AL'),"organization"=>oo.cell(line,'I'),"created_by_user_id" => get_employee_user_id,:current_user_name=>get_user_name,:user_comment=>comments_details}
      # Find Lookup lead source id for "others"
      @cell_str_s=[]
      @cell_str_s << source
      unless source.blank?
        cell_str_s = source.try(:capitalize)
        lookup_lead_source = @company.company_sources.find_by_lvalue_and_company_id(cell_str_s, @comapny.id)#find_by_lvalue(cell_str_s)#.id
        #salutation = salutation_check.blank? ? '' : salutation_check.id
        if lookup_lead_source.nil?
          lookup_lead_source = @company.company_sources.find_by_lvalue_and_company_id('Other', @comapny.id)#find_by_lvalue('Other')
        end
      else
        lookup_lead_source = @company.company_sources.find_by_lvalue_and_company_id('Other', @comapny.id)#.find_by_lvalue('Other')
      end
      #lookup_lead_source = @company.company_sources.find_by_lvalue('Other')
      # Add assigned_to,law_firm_id,source in @contact_details hash.
      @contact_details.merge!("assigned_to_employee_user_id" => assigned_to,"company_id" =>@company.id,:source=>lookup_lead_source.id)

      #Add few required fields details Assigned Lawyers id.
      assigned_false = false
      unless  assigned_to.nil?
        uname = "#{assigned_to.strip}"
        employee_details = User.find(:first, :conditions =>["trim(first_name) || ' ' || trim(last_name) = ? and company_id = ?", uname,@company.id])
        #        employee_details = User.find_by_first_name_and_last_name_and_company_id(column[9].split[0],column[9].split[1],@company.id)
        assigned_to = employee_details.nil?? assigned_false = true : employee_details.id
      else
        assigned_to = nil
      end

      # Below code gives status details depending on status type [Lead,Prospect,Client].
      # Will add this hash in @contact_details hash.
      unless column[43].blank?
        # Blow contact Status ID from look up table.
        cell_str = column[43].try(:capitalize)
        contact_stage = @company.contact_stages.array_to_hash('lvalue')[cell_str]
        if cell_str == "Lead"
          status_typ_id = LeadStatusType.find_by_lvalue_and_company_id('New', @comapny.id).id #.find_by_lvalue('New').id

        else
          status_typ_id = ProspectStatusType.find_by_lvalue_and_company_id('Active', @comapny.id).id #.find_by_lvalue('Active').id
        end
        status_details ={:contact_stage_id=> contact_stage.id,:status_type=>status_typ_id}
        #        lookup_contact_status = Lookup.find(:first,:conditions=>["type='ContactStatus' and lvalue=?",column[44].capitalize])
        #        lead_status_type_ivalue = column[44].capitalize.eql?('Lead')? "New" : "Active"
        #        lead_status_type = column[44].capitalize.eql?('Lead')? "LeadStatusType" : "ProspectStatusType"
        #        # Bleow code find "LeadStatusType" id fron look up table.
        #        lookup_lead_status_type = Lookup.find(:first,:conditions=>["type = ? and lvalue=?",lead_status_type,lead_status_type_ivalue])
        #        status_details ={:status=> lookup_contact_status.id,:status_type=>lookup_lead_status_type.id}
      else
        contact_stage_id = @company.contact_stages.array_hash_value('lvalue','Lead','id')
        status_type_id = LeadStatusType.find_by_lvalue_and_company_id('New', @comapny.id)#.find_by_lvalue("New").id
        status_details ={:contact_stage_id=> contact_stage_id,:status_type=>status_type_id}
        #        lookup_contact_status = Lookup.find(:first,:conditions=>["type='ContactStatus' and lvalue=?","Lead"])
        #        lookup_lead_status_type = Lookup.find(:first,:conditions=>["type = ? and lvalue=?","LeadStatusType","New"])
        #        status_details ={:status=> lookup_contact_status.id,:status_type=>lookup_lead_status_type.id}
      end
      # Add the status_details in @contact_details hash.
      @contact_details.merge!(status_details)
     
      # Create new contact Object
      @contact =Contact.new(@contact_details)

      # Below code is use to add Contact Information form fields information in addresses table.
      @address = @contact.build_address("street"=> p_street,
        "city"=> p_city,
        "state"=> p_state ,
        "zipcode"=> p_zip_code,
        #        "country"=>!column[14].blank??column[14]:'',
        "company_id"=>@contact.company_id)
      @contact_additional_details = @contact.build_contact_additional_field("business_street"=> b_street,
        "business_city"=> b_city,
        "business_state"=> b_state ,
        "business_postal_code"=> b_zip_code,
        "business_fax"=> b_fax,#business_fax,
        "business_phone"=> alt_phone_1,
        "businessphone2"=> alt_phone_2,
        "skype_account"=> skype,
        "linked_in_account"=> linked,
        "facebook_account"=> facebook,
        "twitter_account"=> twitter,
        "others_1"=> others_1,
        "others_2"=> others_2,
        "others_3"=> others_3,
        "others_4"=> others_4,
        "others_5"=> others_5,
        "others_6"=> others_6,
        #        "country"=>!oo.cell(line,'AM').blank?? oo.cell(line,'AM'):'',
        "company_id"=>@contact.company_id)
      # Below code is user to save the contact object.
      if @contact.valid? and !assigned_false
        @contact.save
        # Below code is use to keep count of saved object.
        @valid_length=@valid_length+1
      else
        @contact.errors.add(' ', 'Assigned To Is Invalid') if assigned_false
        # Below code is use to keep count of unsaved object.
        @invalid_length=@invalid_length+1
        # Below code is use to add unsaved @contact error object in  @invalid_contacts array.
        @invalid_contacts << @contact
        # @invalid_contacts << @address
        @assigned_to << assigned_to.to_s
        # Below code is use to generate new csv file for error object which was unable to save in database.
        @csv_string = FasterCSV.generate do |csv|
          # Below code is use to create colum head for the generated csv.

          csv << ['Salutation','First Name','Middle Name','Last Name','Primary Email','Primary Phone','Nick name','Alertnate Email','Source','Source Details','Assigned To','Company','Title','Street','City','State','Zip Code','Fax','Alternate Phone 1','Alternate Phone 2','Website','Street','City','State','Zip Code','Mobile','Fax','Skype Account','Linked In Account','Facebook Account','Twitter Account','Others 1','Others 2','Others 3','Others 4','Others 5','Others 6','','Error Description']
          j = 0
          @invalid_contacts.each do |c|
            salutation_check = @company.salutation_types.find_by_id(c.salutation_id)
            salutation = salutation_check.blank? ? '' : salutation_check.lvalue
            csv << [salutation,c.first_name,c.middle_name,c.last_name,c.email,c.phone,c.nickname,c.alt_email,cell_str_s,c.source_details,@assigned_to[j],c.organization,c.title,c.contact_additional_field.business_street,c.contact_additional_field.business_city,c.contact_additional_field.business_state,c.contact_additional_field.business_postal_code,c.contact_additional_field.business_fax,c.contact_additional_field.business_phone,c.contact_additional_field.businessphone2,c.website,c.address.street,c.address.city,c.address.state,c.address.zipcode,c.mobile,c.fax,c.contact_additional_field.skype_account,c.contact_additional_field.linked_in_account,c.contact_additional_field.facebook_account,c.contact_additional_field.twitter_account,c.contact_additional_field.others_1,c.contact_additional_field.others_2,c.contact_additional_field.others_3,c.contact_additional_field.others_4,c.contact_additional_field.others_5,c.contact_additional_field.others_6,'',c.errors.full_messages.to_s]
            j +=1
          end
          ##          x=0
          ##          adder = []
          ##          # Below code is use to create colum head for the generated csv.
          ##          csv << ['First Name','Last Name','Nick name','Email','Phone','Mobile','Fax','Website','Address : Street','City','State','Zip code','Country','Title','Department','Alternative email','Stage','Assigned to (Lawyer)','Prefernce','Comment','','','Error Decription']
          ##          @invalid_contacts.to_ary.each do |c|
          ##            assigned_to_detail = c[:assigned_to].nil??  nil : Employee.find(:first,:conditions =>["id=?",c[:assigned_to]])
          ##            assigned_name = assigned_to_detail.blank?? nil : "#{assigned_to_detail[:first_name]}  #{assigned_to_detail[:last_name]}"
          ##            lookup_lead_status_type = c[:status]? Lookup.find(:first,:conditions=>["id=?",c[:status]]).lvalue : ""
          ##            adder[0] = c[:first_name]if !c[:first_name].nil?
          ##            adder[1] = c[:last_name] if !c[:last_name].nil?
          ##            adder[2] = c[:nickname] if !c[:nickname].nil?
          ##            adder[3] = c[:email] if !c[:email].nil?
          ##            adder[4] = c[:phone] if !c[:phone].nil?
          ##            adder[5] = c[:mobile] if !c[:mobile].nil?
          ##            adder[6] = c[:fax] if !c[:fax].nil?
          ##            adder[7] = c[:website] if !c[:website].nil?
          ##            adder[8] = c[:street] if !c[:street].nil?
          ##            adder[9] = c[:city] if !c[:city].nil?
          ##            adder[10] = c[:state] if !c[:state].nil?
          ##            adder[11] = c[:zipcode] if !c[:zipcode].nil?
          ##            adder[12] = c[:country] if !c[:country].nil?
          ##            adder[13] = c[:title] if !c[:title].nil?
          ##            adder[14] = c[:department] if !c[:department].nil?
          ##            adder[15] = c[:alt_email] if !c[:alt_email].nil?
          ##            adder[44] = lookup_lead_status_type if !c[:status].nil?
          ##            adder[17] = assigned_name if !c[:assigned_to].nil?
          ##            adder[18] = c[:preference] if !c[:preference].nil?
          ##            begin
          ##              adder[19] = c.user_comment.to_s
          ##            rescue
          ##            end
          ##            adder[20] = ''
          ##            adder[21] = ''
          ##            adder[22] = c.errors.full_messages.to_s if !c[:preference].nil?
          ##            if( x % 2 == 1)
          ##              csv << adder.flatten
          ##            end
          ##            x+=1
          ##          end
        end
      end
    end
  end

  def import_campaign_members_process(params)
    @invalid_members=[]
    @invalid_member_length= 0
    @valid_member_length= 0
    @campaign =Campaign.find(params["campaign_id"])
    @company = Company.find(@campaign.company_id)

    if params[:file_format]=='CSV'
      unless params["import_file"].blank?
        @parser = CSV::Reader.parse(params["import_file"])
    
        @parser.each_with_index do |column,i|
          if i > 1
            @campaign_member= CampaignMember.new(:campaign_id=>@campaign.id, :campaign_member_status_type_id=>@company.campaign_member_status_types.find_by_lvalue('New').id,:first_name=>column[0], :last_name=> column[1], :nickname=>column[2],:email=> column[3], :phone=>column[4], :mobile=>column[5],:fax=>column[6],:website=>column[7],:title=>column[8], :company_id=> @campaign.company_id, :employee_user_id=> get_employee_user_id, :created_by_user_id=>current_user.id  )
            if @campaign_member.save
              @valid_member_length=@valid_member_length+1
            else
              @invalid_member_length=@invalid_member_length+1
              @invalid_members << @campaign_member
                         
              @csv_string = FasterCSV.generate do |csv|
                csv << ['First name',	'Last name',	'Nick name',	'Primary Email',	'Primary Phone',	'Mobile',	'Fax',	'Website',	'Title','','','Error Description']
                @invalid_members.each do |c|
                  csv << [c.first_name,c.last_name,c.nickname,c.email,c.phone,c.mobile,c.fax,c.website,c.title,'','',c.errors.full_messages]
                end

              end
            end
          end
        end
      end
    else
     
      #XLS CODE STARTS
      unless params["import_file"].blank?
        name = params["import_file"].original_filename
        directory = "assets/"
        path = File.join(directory, name)
        File.open(path, "wb") { |f| f.write(params["import_file"].read) }
        ext = File.extname(name)
        if ext==".xls"
          oo= Excel.new(path)
        elsif ext==".xlsx"
          oo= Excelx.new(path)
        elsif ext==".ods"
          oo = Openoffice.new(path)
        end
        oo.default_sheet = oo.sheets.first
        3.upto(oo.last_row) do |line|
          #contacts_excel_parsing(oo,line)
          if oo.cell(line,'D').present?
            email=oo.cell(line,'D').to_s
          end
         
          if oo.cell(line,'E').present?
            phone=oo.cell(line,'E')
            begin
              if oo.cell(line,'E').to_i>0
                phone= oo.cell(line,'E').floor
              else
                phone = oo.cell(line,'E').to_s
              end
            rescue          
            end
          end
          if oo.cell(line,'F').present?
            mobile=oo.cell(line,'F')
            begin
              if oo.cell(line,'F').to_i>0
                mobile= oo.cell(line,'F').floor
              else
                mobile=oo.cell(line,'F')
              end
            rescue
            end
          end

          @campaign_member= CampaignMember.new(:campaign_id=>@campaign.id, :campaign_member_status_type_id=>@company.campaign_member_status_types.find_by_lvalue('New').id,:first_name=>oo.cell(line,'A').to_s, :last_name=> oo.cell(line,'B').to_s, :nickname=>oo.cell(line,'C'),:email=> email, :phone=>phone.to_s, :mobile=>mobile.to_s,:fax=>oo.cell(line,'G').to_s,:website=>oo.cell(line,'H'),:title=>oo.cell(line,'I'), :company_id=> @campaign.company_id, :employee_user_id=> get_employee_user_id, :created_by_user_id=>current_user.id  )
          if @campaign_member.save
            @valid_member_length=@valid_member_length+1
          else
            @invalid_member_length=@invalid_member_length+1
            @invalid_members << @campaign_member
            @csv_string = FasterCSV.generate do |csv|
              csv << ['First name',	'Last name',	'Nick name',	'Email',	'Phone',	'Mobile',	'Fax',	'Website',	'Title','','','Error Description']
              @invalid_members.each do |c|
                csv << [c.first_name,c.last_name,c.nickname,c.email,c.phone,c.mobile,c.fax,c.website,c.title,'','',c.errors.full_messages]
              end
            end
          end
        end
      end
      #XLS END
    end
  end

  def self.time_entry_process_excel_file(file_name,file,current_user,company,employee_user)

    directory =  "#{RAILS_ROOT}/assets/"
    path = File.join(directory, file_name)
    File.open(path, "wb") { |f| f.write(file) }
    ext = File.extname(file_name)
    if ext==".xls"
      object = Excel.new(path)
    elsif ext==".xlsx"
      object = Excelx.new(path)
    elsif ext==".ods"
      object = Openoffice.new(path)
    end
    
    object.default_sheet = object.sheets.first

    @company = company
    @current_user = current_user
    @e_f_n = []
    @e_l_n = []
    @matt = []
    @report = nil
    @sheet = nil
    @invalid_entries = []
    @invalid_length = 0
    @valid_length = 0

    3.upto(object.last_row) do |line|
      self.time_entry_excel_parsing(object,line)
    end

    begin
      err_directory = "public/"
      err_filename="invalid_time_entries_report_#{Time.now}.xls"
      err_path = File.join(err_directory,err_filename)
      File.open(err_path, "wb") { |f| f.write(@xls_string.string) }
      send_notification_for_invalid_entry(err_path,@current_user,@invalid_length,@valid_length,employee_user)
      File.delete("#{RAILS_ROOT}/public/#{err_filename}")
      File.delete("#{RAILS_ROOT}/assets/#{file_name}")
    rescue Exception=>ex
      #send notification for any failure
      puts ex.message
    end
  end


  def self.time_entry_excel_parsing(object,line)

    if object.cell(line,'A').present?
      time_entry_date = object.cell(line,'A').to_s
    end

    if object.cell(line,'H').present?
      activity_type = object.cell(line,'H')
    else
      activity_type = 'Other'
    end

    activity_type = @company.activity_types.find(:first, :conditions => ["lvalue ilike ? ",activity_type])
    activity_type_id = activity_type.id if activity_type.present?

    if object.cell(line,'I').present?
      description = object.cell(line,'I')
    end

    if object.cell(line,'J').present?
      start_time = object.cell(line,'J').to_s
      start_time = Time.parse(time_entry_date +" "+ start_time)
    end

    if object.cell(line,'K').present?
      end_time = object.cell(line,'K').to_s
      end_time = Time.parse(time_entry_date +" "+ end_time)
    end
    time_entry_date = Date.parse(time_entry_date)

    if object.cell(line,'L').present?
      duration = (object.cell(line,'L')).to_f.roundf2(2)
      if (start_time.present? && end_time.present?)
        dur = ((end_time - start_time)/1.hours).roundf2(2)
        start_time = end_time = "" if dur != duration
      end
    end

    if object.cell(line,'M').present?
      rate = object.cell(line,'M')
    end

    if object.cell(line,'N').present?
      billable = object.cell(line,'N')
      if billable.eql?('Yes')
        is_billable = true
      else
        is_billable = false
      end
    else
      is_billable = false
    end


    if object.cell(line,'O').present?
      final_amt = object.cell(line,'O')
    end
    employee_present = true
    if object.cell(line,'B').present?
      employee_name = object.cell(line,'B').to_s.strip
      e_condition = "trim(first_name)"
      if object.cell(line,'C').present?
        employee_name = employee_name + ' ' + object.cell(line,'C').to_s.strip
        e_condition += " || ' ' || trim(last_name)"
      end
    end

    employee_user = @company.employees.find(:first, :conditions => ["("+ e_condition +") ilike ?",employee_name]);

    if employee_user.present?
      employee_user_id = employee_user.user_id
    else
      employee_present = false
    end

    if object.cell(line,'D').present?
      matter_name = object.cell(line,'D').to_s.strip
      matter = @company.matters.find(:first, :conditions => ['name ilike ?',matter_name])
      matter_id = matter.id if matter.present?
    end

    if object.cell(line,'E').present?
      contact_name = object.cell(line,'E').to_s.strip
      condition = "trim(first_name)"
      if object.cell(line,'F').present?
        contact_name = contact_name + ' ' + object.cell(line,'F').to_s.strip
        condition += " || ' ' || trim(middle_name)"
      end
      if object.cell(line,'G').present?
        contact_name = contact_name + ' ' + object.cell(line,'G').to_s.strip
        condition += " || ' ' || trim(last_name)"
      end

      contact = @company.contacts.find(:first, :conditions => ["("+ condition +") ilike ? ", contact_name])

      contact_id = contact.id if contact.present?
    end

    time_entries = {"employee_user_id" => employee_user_id, "created_by_user_id" => @current_user.id,
                    "activity_type" => activity_type_id, "description" => description.to_s,
                    "time_entry_date" => time_entry_date, "start_time" => start_time, "end_time" => end_time,
                    "actual_duration" => duration, "billing_method_type" => 1,
                    "final_billed_amount" => final_amt, "contact_id" => contact_id, "matter_id" => matter_id,
                    "company_id" => @company.id, "status" => 'Open', "is_billable" => is_billable,
                    "is_internal" => false, "actual_activity_rate" => rate, "activity_rate" => rate
                    }

    new_entry = Physical::Timeandexpenses::TimeEntry.new(time_entries)

    if new_entry.valid? && employee_present
      #new_entry.send(:create_without_callbacks)
      new_entry.save
      @valid_length = @valid_length+1
    else
      @invalid_entries << new_entry
      new_entry.errors.add(' ', 'Employee Detail Is Not Valid') unless employee_present
      errors = new_entry.errors

      @invalid_length = @invalid_length + 1
      if @report.nil?
        @report = Spreadsheet::Workbook.new
        @sheet = @report.create_worksheet
        @sheet.row(1).concat ['Date','Emp First Name','Emp Last Name','Matter Name','First Name','Middle Name','Last Name','Activity Type','Description','Start Time','End Time','Duration','Rate/Hr','Billable','Final Amount','Error Message']
        @xls_string = StringIO.new ''
        @sheet.row(@invalid_length + 1).concat [object.cell(line,'A').to_s,object.cell(line,'B').to_s,object.cell(line,'C').to_s,object.cell(line,'D').to_s,object.cell(line,'E').to_s,object.cell(line,'F').to_s,object.cell(line,'G').to_s,object.cell(line,'H').to_s,object.cell(line,'I').to_s,object.cell(line,'J').to_s,object.cell(line,'K').to_s,object.cell(line,'L').to_s,object.cell(line,'M').to_s,object.cell(line,'N').to_s,object.cell(line,'O').to_s,errors.full_messages.to_s] if new_entry.present?
        @report.write(@xls_string)
      else
        @sheet.row(@invalid_length + 1).concat [object.cell(line,'A').to_s,object.cell(line,'B').to_s,object.cell(line,'C').to_s,object.cell(line,'D').to_s,object.cell(line,'E').to_s,object.cell(line,'F').to_s,object.cell(line,'G').to_s,object.cell(line,'H').to_s,object.cell(line,'I').to_s,object.cell(line,'J').to_s,object.cell(line,'K').to_s,object.cell(line,'L').to_s,object.cell(line,'M').to_s,object.cell(line,'N').to_s,object.cell(line,'O').to_s,errors.full_messages.to_s] if new_entry.present?
        @report.write(@xls_string)
      end

    end

    
  end

end
