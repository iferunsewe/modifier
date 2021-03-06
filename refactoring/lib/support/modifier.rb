require 'csv'

module Support
  DEFAULT_CSV_OPTIONS = {:col_sep => "\t", :headers => :first_row}
  DEFAULT_WRITE_CSV_OPTIONS = DEFAULT_CSV_OPTIONS.merge(:row_sep => "\r\n") #Avoids duplication of method above
  class Modifier

    KEYWORD_UNIQUE_ID = 'Keyword Unique ID'
    LAST_VALUE_WINS = ['Account ID', 'Account Name', 'Campaign', 'Ad Group', 'Keyword', 'Keyword Type', 'Subid', 'Paused', 'Max CPC', 'Keyword Unique ID', 'ACCOUNT', 'CAMPAIGN', 'BRAND', 'BRAND+CATEGORY', 'ADGROUP', 'KEYWORD']
    LAST_REAL_VALUE_WINS = ['Last Avg CPC', 'Last Avg Pos']
    INT_VALUES = ['Clicks', 'Impressions', 'ACCOUNT - Clicks', 'CAMPAIGN - Clicks', 'BRAND - Clicks', 'BRAND+CATEGORY - Clicks', 'ADGROUP - Clicks', 'KEYWORD - Clicks']
    FLOAT_VALUES = ['Avg CPC', 'CTR', 'Est EPC', 'newBid', 'Costs', 'Avg Pos']

    LINES_PER_FILE = 120000

    def initialize(saleamount_factor, cancellation_factor)
      @saleamount_factor = saleamount_factor
      @cancellation_factor = cancellation_factor
    end

    def modify(output, input)
      input = Transformer.sort(input)

      input_enumerator = lazy_read(input)

      combiner = combining(input_enumerator)

      merger = merging(combiner)

      create_new_output(output, merger)

    end

    private

    def create_new_output(output, merger)
      done = false
      file_index = 0
      file_name = output.gsub('.txt', '')
      while !done do
        CSV.open(file_name + "_#{file_index}.txt", "wb", DEFAULT_WRITE_CSV_OPTIONS) do |csv|
          headers_written = false
          line_count = 0
          while line_count < LINES_PER_FILE
            begin
              merged = merger.next
              if !headers_written
                csv << merged.keys
                headers_written = true
                line_count +=1
              end
              csv << merged
              line_count +=1
            rescue StopIteration
              done = true
              break
            end
          end
          file_index += 1
        end
      end
    end

    def combining(input_enumerator)
      Combiner.new do |value|
        value[KEYWORD_UNIQUE_ID]
      end.combine(input_enumerator)
    end

    def merging(combiner)
      Enumerator.new do |yielder|
        while true
          begin
            list_of_rows = combiner.next
            merged = combine_hashes(list_of_rows)
            yielder.yield(combine_values(merged))
          rescue StopIteration
            break
          end
        end
      end
    end

    def combine_values(hash)
      LAST_VALUE_WINS.each do |key|
        hash[key] = hash[key].last
      end
      LAST_REAL_VALUE_WINS.each do |key|
        hash[key] = hash[key].select { |v| not (v.nil? or v == 0 or v == '0' or v == '') }.last
      end
      INT_VALUES.each do |key|
        hash[key] = hash[key][0].to_s
      end
      FLOAT_VALUES.each do |key|
        hash[key] = hash[key][0].from_german_to_f.to_german_s
      end
      ['number of commissions'].each do |key|
        hash[key] = (@cancellation_factor * hash[key][0].from_german_to_f).to_german_s
      end
      ['Commission Value', 'ACCOUNT - Commission Value', 'CAMPAIGN - Commission Value', 'BRAND - Commission Value', 'BRAND+CATEGORY - Commission Value', 'ADGROUP - Commission Value', 'KEYWORD - Commission Value'].each do |key|
        hash[key] = (@cancellation_factor * @saleamount_factor * hash[key][0].from_german_to_f).to_german_s
      end
      hash
    end

    def combine_hashes(list_of_rows)
      list_of_rows.each_with_object(Hash.new {|hash, key| hash[key] = []}) do |row, hashes|
        next if row.nil?
          row.each do |k, v|
            hashes[k] << v
          end
        end
    end

    def lazy_read(file)
      Enumerator.new do |yielder|
        CSV.foreach(file, DEFAULT_CSV_OPTIONS) do |row|
          yielder.yield(row)
        end
      end
    end
  end
end