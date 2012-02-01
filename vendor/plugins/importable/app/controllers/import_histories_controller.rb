class ImportHistoriesController < ApplicationController
  layout 'admin'
  def index
    authorize!(:index,current_user) unless current_user.role?:livia_admin
    !params[:company_id].blank?? session[:company_id] = params[:company_id] : params[:company_id] = session[:company_id]
    @companies ||=Company.company(current_user.company_id)
    @import_histories = ImportHistory.find_all_by_company_id(params[:company_id])
    @company ||=Company.find(params[:company_id]) unless params[:company_id].nil?
 
  end

  def list
    authorize!(:list,current_user) unless current_user.role?:livia_admin
    session[:company_id] = params[:company_id]
    @company=  Company.find(params[:company_id])
    @import_histories = ImportHistory.find_all_by_company_id(@company.id)
  end
  
  def download_original_import_file
    authorize!(:list,current_user) unless ( current_user.role?:livia_admin  || current_user.role?(:lawyer) )
    @import_history = ImportHistory.find(params[:id])
    if @import_history.present? && File.exist?("#{RAILS_ROOT}/#{@import_history.original_filename}")
      send_file("#{RAILS_ROOT}/#{@import_history.original_filename}")
    else
      redirect_to :back
    end
  end
  
  def download_invalid_import_file
    authorize!(:list,current_user) unless (current_user.role?(:livia_admin)  || current_user.role?(:lawyer) )
    @import_history = ImportHistory.find(params[:id])
    if @import_history.present? && File.exist?("#{RAILS_ROOT}/#{@import_history.error_filename}")
      send_file("#{RAILS_ROOT}/#{@import_history.error_filename}")
    else
      redirect_to :back
    end
  end

  def display_contact_import_histories
    @company = Company.find(get_company_id)
    @import_histories = ImportHistory.find_all_by_company_id_and_module_type(get_company_id,'Contact')
    if !@from.empty?
      @set_path = '/excel_imports?module_type=contact&from=utility'
    else
    @set_path = contacts_path
    end
    render :layout => 'full_screen'
  end

  def display_matter_import_histories
    @company = Company.find(get_company_id)
    @import_histories = ImportHistory.find_all_by_company_id_and_module_type(get_company_id,'Matter')
    if !@from.empty?
      @set_path = '/excel_imports?module_type=matter&from=utility'
    else
    @set_path = matters_path  
    end

    render :layout => 'full_screen'
  end

  def display_time_import_histories
    @company = Company.find(get_company_id)
    @import_histories = ImportHistory.find_all_by_company_id_and_module_type(get_company_id,'Time')
    if !@extra_parameter.empty?
      @set_path = "/physical/timeandexpenses/time_and_expenses/new?time_entry_date=#{@extra_parameter}"
    else
      @set_path = "/excel_imports/index?module_type=time"
    end
    render :layout => 'full_screen'
  end

  def display_expense_import_histories
    @company = Company.find(get_company_id)
    @import_histories = ImportHistory.find_all_by_company_id_and_module_type(get_company_id,'Expense')
    if !@extra_parameter.empty?
      @set_path = "/physical/timeandexpenses/time_and_expenses/new?time_entry_date=#{@extra_parameter}"
    else
      @set_path = "/excel_imports/index?module_type=expense"
    end
    render :layout => 'full_screen'
  end

  def display_campaign_member_import_histories
    @company = Company.find(get_company_id)
    @import_histories = ImportHistory.find_all_by_company_id_and_module_type(get_company_id,'CampaignMember')
    @set_path = edit_campaign_path(@extra_parameter,"mode_type"=>"MY","per_page"=>25)+"#fragment-1"
    render :layout => 'full_screen'
  end

  def display_import_history
    @extra_parameter = params[:other_parameter] if params[:other_parameter]
    @from = params[:from] if params[:from]
    @module_type = params[:module_type] || "contact"
    if @module_type == "contact"
      @bread_crumb_name = t(:text_menu_contacts)
      display_contact_import_histories      
    elsif  @module_type == "time"
      @bread_crumb_name = "Time"
      display_time_import_histories      
    elsif  @module_type == "expense"
      @bread_crumb_name = "Expense"
      display_expense_import_histories      
    elsif  @module_type == "matter"
      @bread_crumb_name = t(:text_menu_matter)
      display_matter_import_histories      
    elsif  @module_type == "campaign_member"
      @bread_crumb_name = "Campaign Members"
      display_campaign_member_import_histories      
    end
  end

end
