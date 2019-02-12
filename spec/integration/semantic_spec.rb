# spec/integration/semantic_spec.rb
# cat data_seismic.ttl | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g; s/\"/\\"/g' | echo "{\"content\":\"$(cat - )\"}" | jq > data_seismic.ttl.json

require 'swagger_helper'

describe 'SEMCON USAGE API' do
	path '/api/data' do
		post 'write data' do # write RDF
			before do
				Semantic.destroy_all
				@sem = Semantic.new(validation: file_fixture("init_seismic.trig").read)
				@sem.save!
			end
			tags 'Semantic'
			consumes 'application/json'
			parameter name: :input, in: :body
			response '200', 'success' do
				let(:input) { JSON.parse(file_fixture("data_seismic.ttl.json").read) }
				run_test! do
					expect(Store.count).to eq(2)
					expect(Log.count).to eq(1)
				end
			end
			response '500', 'invalid input' do
				let(:input) { "" }
				run_test!
			end
		end
	end

	path '/api/data/plain' do
		get 'read raw data' do
			before do
				Semantic.destroy_all
				@sem = Semantic.new(validation: file_fixture("init_format_csv.trig").read)
				@sem.save!
				Store.destroy_all
				@store = Store.new(item: "22332;\"Klagenfurt/Flughafen\";447;\"25-02-2029\";\"25:00\";-2,3;-5,4;73;256;5;268;23,7;0;2022,3;956,8;200")
				@store.save!
			end
			tags 'Format'
			produces 'application/json'
			response '200', 'success' do
				run_test! do |response|
					data = response.body
					data_parsed = CSV.parse(data, col_sep: ";")
					expect(data_parsed.first.length).to eq(16)
					expect(Log.count).to eq(1)
				end
			end
		end
	end
end
