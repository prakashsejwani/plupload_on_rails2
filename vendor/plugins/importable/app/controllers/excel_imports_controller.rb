
require 'excel_import'
class ExcelImportsController < ApplicationController
  
  def index
    @module_type = params[:module_type] || "contact"
    if params[:campaign_id].present? && @module_type== "campaign_member"
      company = Company.find(get_company_id)
      @campaign_id = params[:campaign_id]
      @campaign = company.campaigns.find(params[:campaign_id])
    end

    if @module_type == "contact"
      bread_crumb_name = t(:text_menu_contacts)
      @set_path = contacts_path
    elsif  @module_type == "time"
      bread_crumb_name = "Time"
    elsif  @module_type == "expense"
      bread_crumb_name = "Expense"
    elsif  @module_type == "matter"
      bread_crumb_name = t(:text_menu_matter)
      @set_path = matters_path
    elsif  @module_type == "campaign_member"
      bread_crumb_name = "Campaign Members"
    end
    @bread_crumb_name = bread_crumb_name
    render :layout => 'full_screen'
  end
  
  def import
    set_import_model
    responds_to_parent do
      render :update do |page|
        if flash[:error].present?
         page << "show_error_msg('imports_notice','Invalid File','message_error_div');"
         page["#import-content"].html('')
        else
        page["#import-content"].html(render(:partial=>'import_summary'))
        end
      end
    end   
  end
   
  def import_contacts
    if params[:import_file].present?
      contact_import_from_file
    else
      contact_import_from_invalid_records
    end
  end

  def contact_import_from_file
    @import_history= ImportHistory.new({:company_id=>get_company_id,:employee_user_id=>get_employee_user_id,:owner_id=>current_user.id,:module_type=>"Contact"})
    if @import_history.save
      file_path,invalid_file_path = save_data_file(params[:import_file],@import_history.id)
      excel_bounds = {"first_row"=>1,"header_row"=>1}
      @import = ContactImport.new(get_employee_user_id,get_company_id,invalid_file_path,file_path,{"boundry"=>excel_bounds})
      @import.import_records
      @excel_headers = ContactImport::EXCEL_HEADERS
      update_import_history(invalid_file_path,@import.valid_records,@import.invalid_records,file_path)
    end 
  end

  def contact_import_from_invalid_records
    parent_id = ImportHistory.find(params[:import_history_id]).id rescue nil
    @import_history= ImportHistory.new({:company_id=>get_company_id,:employee_user_id=>get_employee_user_id,:owner_id=>current_user.id,:module_type=>"Contact"}) 
    @headers = ContactImport::HEADERS
    @excel_headers = ContactImport::EXCEL_HEADERS
    @records  = [@headers]
    params[:invalid_records].each do |record|
      @records << ExcelImport.rearrange_hash_to_array(record,@headers) 
    end
    if @import_history.save
      file_path,invalid_file_path = import_file_name_format(@import_history.id, "xls")
      @import = ContactImport.new(get_employee_user_id,get_company_id,invalid_file_path,@records)
      @import.import_records
      update_import_history(invalid_file_path,@import.valid_records,@import.invalid_records,nil,parent_id)
    end
  end
 
  def import_time_entries
    if params[:import_file].present?
      time_import_from_file
    else
      time_import_from_invalid_records
    end
  end

  def time_import_from_invalid_records
    parent_id = ImportHistory.find(params[:import_history_id]).id rescue nil
    @import_history= ImportHistory.new({:company_id=>get_company_id,:employee_user_id=>get_employee_user_id,:owner_id=>current_user.id,:module_type=>"Time"})
    @headers = Timeimport::HEADERS
    @records  = [@headers]
    @excel_headers = Timeimport::EXCEL_HEADERS
    params[:invalid_records].each do |record|
      @records << ExcelImport.rearrange_hash_to_array(record,@headers)
    end
    if @import_history.save
      file_path,invalid_file_path = import_file_name_format(@import_history.id, "xls")
      @import = Timeimport.new(current_user.id,get_employee_user_id,get_company_id,invalid_file_path,@records)
      @import.import_records
      update_import_history(invalid_file_path,@import.valid_records,@import.invalid_records,nil,parent_id)
    end
  end

  def time_import_from_file
    @import_history= ImportHistory.new({:company_id=>get_company_id,:employee_user_id=>get_employee_user_id,:owner_id=>current_user.id,:module_type=>"Time"})
    if @import_history.save
      file_path,invalid_file_path = save_data_file(params[:import_file],@import_history.id)
      excel_bounds = {"first_row"=>3,"header_row"=>3}
      @import = Timeimport.new(current_user.id,get_employee_user_id,get_company_id,invalid_file_path,file_path,{"boundry"=>excel_bounds})
      @import.import_records
      @excel_headers = Timeimport::EXCEL_HEADERS
      update_import_history(invalid_file_path,@import.valid_records,@import.invalid_records,file_path)
    end
  end


  def import_expense_entries
    if params[:import_file].present?
      expense_import_from_file
    else
      expense_import_from_invalid_records
    end
  end

  def expense_import_from_file
    @import_history= ImportHistory.new({:company_id=>get_company_id,:employee_user_id=>get_employee_user_id,:owner_id=>current_user.id,:module_type=>"Expense"})
    if @import_history.save
      file_path,invalid_file_path = save_data_file(params[:import_file],@import_history.id)
      excel_bounds = {"first_row"=>3,"header_row"=>3}
      @import = ExpenseImport.new(current_user.id,get_employee_user_id,get_company_id,invalid_file_path,file_path,{"boundry"=>excel_bounds})
      @import.import_records
      @excel_headers = ExpenseImport::EXCEL_HEADERS
      update_import_history(invalid_file_path,@import.valid_records,@import.invalid_records,file_path)
    end
  end

   def expense_import_from_invalid_records
    parent_id = ImportHistory.find(params[:import_history_id]).id rescue nil
    @import_history= ImportHistory.new({:company_id=>get_company_id,:employee_user_id=>get_employee_user_id,:owner_id=>current_user.id,:module_type=>"Expense"})
    @headers = ExpenseImport::HEADERS
    @records  = [@headers]
    @excel_headers = ExpenseImport::EXCEL_HEADERS
    params[:invalid_records].each do |record|
      @records << ExcelImport.rearrange_hash_to_array(record,@headers)
    end
    if @import_history.save
      file_path,invalid_file_path = import_file_name_format(@import_history.id, "xls")
      @import = ExpenseImport.new(current_user.id,get_employee_user_id,get_company_id,invalid_file_path,@records)
      @import.import_records
      update_import_history(invalid_file_path,@import.valid_records,@import.invalid_records,nil,parent_id)
    end
  end
  
  def import_campaign_members
    @company = Company.find(get_company_id)
    @campaign = @company.campaigns.find(params[:campaign_id])
    if @campaign.present?
      @campaign_id = @campaign.id
      if params[:import_file].present?
        campaign_members_import_from_file
      else
        campaign_members_from_invalid_records
      end
    end
  end
  def campaign_members_import_from_file
     @import_history= ImportHistory.new({:company_id=>get_company_id,:employee_user_id=>get_employee_user_id,:owner_id=>current_user.id,:module_type=>"CampaignMember"})
    if @import_history.save
      file_path,invalid_file_path = save_data_file(params[:import_file],@import_history.id)
      excel_bounds = {"first_row"=>3,"header_row"=>2}
      @import = CampaignMembersImport.new(current_user.id,get_employee_user_id,get_company_id,@campaign.id,invalid_file_path,file_path,{"boundry"=>excel_bounds})
      @import.import_records
      @file_error_message = @import.validate_file
      if @file_error_message.present?
        flash.now[:error] = true
      else
        @excel_headers = CampaignMembersImport::EXCEL_HEADERS
        update_import_history(invalid_file_path,@import.valid_records,@import.invalid_records,file_path)
      end
    end
  end
  def campaign_members_from_invalid_records
    parent_id = ImportHistory.find(params[:import_history_id]).id rescue nil
    @import_history= ImportHistory.new({:company_id=>get_company_id,:employee_user_id=>get_employee_user_id,:owner_id=>current_user.id,:module_type=>"CampaignMember"})
    @headers = CampaignMembersImport::HEADERS
    @records  = [@headers]
    @excel_headers = CampaignMembersImport::EXCEL_HEADERS
    params[:invalid_records].each do |record|
      @records << ExcelImport.rearrange_hash_to_array(record,@headers)
    end
    if @import_history.save
      file_path,invalid_file_path = import_file_name_format(@import_history.id, "xls")
      @import = CampaignMembersImport.new(current_user.id,get_employee_user_id,get_company_id,@campaign.id,invalid_file_path,@records)
      @import.import_records
      update_import_history(invalid_file_path,@import.valid_records,@import.invalid_records,nil,parent_id)
    end
  end
  def import_matters
    if params[:import_file].present?
      matter_import_from_file
    else
      matter_import_from_invalid_records
    end
  end

  def matter_import_from_file
    @import_history= ImportHistory.new({:company_id=>get_company_id,:employee_user_id=>get_employee_user_id,:owner_id=>current_user.id,:module_type=>"Matter"})
    if @import_history.save
      file_path,invalid_file_path = save_data_file(params[:import_file],@import_history.id)
      excel_bounds = {"first_row"=>3,"header_row"=>3}
      @import = MatterImport.new(current_user.id,get_employee_user_id,get_company_id,invalid_file_path,file_path,{"boundry"=>excel_bounds})
      @file_error_message = @import.validate_file
      if @file_error_message.present?
       flash.now[:error] = true
      else
       @import.import_records
       @excel_headers = MatterImport::EXCEL_HEADERS
       update_import_history(invalid_file_path,@import.valid_records,@import.invalid_records,file_path)
      end
    end
  end

  def matter_import_from_invalid_records
    parent_id = ImportHistory.find(params[:import_history_id]).id rescue nil
    @import_history= ImportHistory.new({:company_id=>get_company_id,:employee_user_id=>get_employee_user_id,:owner_id=>current_user.id,:module_type=>"Matter"})
    @headers = MatterImport::HEADERS
    @excel_headers = MatterImport::EXCEL_HEADERS
    @records  = [@headers]
    params[:invalid_records].each do |record|
      @records << ExcelImport.rearrange_hash_to_array(record,@headers)
    end
    if @import_history.save
      file_path,invalid_file_path = import_file_name_format(@import_history.id, "xls")
      @import = MatterImport.new(current_user.id,get_employee_user_id,get_company_id,invalid_file_path,@records)
      @import.import_records
      update_import_history(invalid_file_path,@import.valid_records,@import.invalid_records,nil,parent_id)
    end
  end

  def import_form
    render :layout => 'full_screen'
  end

  def download_invalid_excel_file
    @import_history = ImportHistory.find(params[:import_history_id])
    send_file("#{RAILS_ROOT}/#{@import_history.error_filename}")
  end

  def download_template
    @module_type = params[:module_type] || "contact"
    path = "/public/sample_import_files/"
    if @module_type == "contact"
      send_file RAILS_ROOT + path + "contacts_import.xls", :type => "application/xls"
    elsif  @module_type == "time"
      send_file RAILS_ROOT + path + "time_entries_import_file.xls", :type => "application/xls"
    elsif  @module_type == "expense"
      send_file RAILS_ROOT+ path +"expense_entries_import_file.xls", :type => "application/xls"
    elsif  @module_type == "matter"
      send_file RAILS_ROOT+ path +"matters_import_file.xls", :type => "application/xls"
    elsif  @module_type == "campaign_member"
      send_file RAILS_ROOT+ path +"campaign_import_file.xls", :type => "application/xls"
    end
  end

  protected
  
  def update_import_history(error_path,valid_records,invalid_records,file_path=nil,parent_id=nil)
    @import_history.original_filename = file_path
    @import_history.error_filename = error_path
    @import_history.valid_records = valid_records.size
    @import_history.invalid_records = invalid_records.size
    @import_history.valid_record_ids = valid_records.map{|r|r[0]}.collect(& :id).join(",") rescue ""
    @import_history.parent_id = parent_id
    @import_history.save    
  end

  ImportPath="assets/imports"
  def import_file_name_format(import_id, ext)
    # format is import_id and timestamp 
    FileUtils.mkdir_p("#{RAILS_ROOT}/#{ImportPath}/#{get_company_id}/#{import_id}")
    file_path = "#{import_id}_#{Time.now.to_i}_orig.#{ext}"
    error_file_path ="#{import_id}_#{Time.now.to_i}_error.#{ext}"
    path = File.join(ImportPath, "#{get_company_id}/#{import_id}/#{file_path}")
    error = File.join(ImportPath, "#{get_company_id}/#{import_id}/#{error_file_path}")
    return path,error
  end

  def save_data_file(import_file, import_id)
    ext = import_file.original_filename.split(".").last
    path,error = import_file_name_format(import_id,ext)
    File.open(path, "wb") { |f| f.write(import_file.read) }
    return path,error
  end
  
  def set_import_model
    @module_type = params[:module_type] || "contact"
    if @module_type == "contact"
      import_contacts
    elsif  @module_type == "time"
      import_time_entries
    elsif  @module_type == "expense"
      import_expense_entries
    elsif @module_type == "matter"
      import_matters
    elsif @module_type == "campaign_member"
      import_campaign_members
    end
  end
  
end
