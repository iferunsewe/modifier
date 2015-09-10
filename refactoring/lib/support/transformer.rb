module Support
  class Transformer
    def self.sort(file)
      output = "#{file}.sorted"
      content_as_table = parse(file)
      headers = content_as_table.headers
      index_of_key = headers.index('Clicks')
      content = content_as_table.sort_by { |a| -a[index_of_key].to_i }
      write(content, headers, output)
      output
    end

    def self.write(content, headers, output)
      CSV.open(output, "wb", {:col_sep => "\t", :headers => :first_row, :row_sep => "\r\n"}) do |csv|
        csv << headers
        content.each do |row|
          csv << row
        end
      end
    end

    def self.parse(file)
      CSV.read(file, DEFAULT_CSV_OPTIONS)
    end
  end
end