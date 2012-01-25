# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
 def help_links(name)
  help = Help.find_by_name(name)
  return help.content
 end

end
