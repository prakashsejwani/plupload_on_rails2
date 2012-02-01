module ImportExport
end

if RUBY_VERSION =~ /^1\.8\./
  require 'rubygems'
  require 'faster_csv'
  ::ImportExport::CSV = ::FasterCSV
else
  require 'csv'
  ::ImportExport::CSV = ::CSV
end
