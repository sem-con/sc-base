# spec/integration/format_spec.rb
# cat test_valid.csv | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g; s/\"/\\"/g' | echo "{\"content\":\"$(cat - )\"}" | jq > test_valid.csv.json

require 'swagger_helper'

describe 'SEMCON USAGE API' do
	path '/api/data' do
		post 'write data' do # write CSV
			before do
				Semantic.destroy_all
				@sem = Semantic.new(validation: file_fixture("init_format_csv.trig").read)
				@sem.save!
			end
			tags 'Data access'
			consumes 'application/json'
			parameter name: :input, in: :body
			response '200', 'success' do
				let(:input) { JSON.parse(file_fixture("test_valid.csv.json").read) }
				run_test! do
					expect(Store.count).to eq(22)
					expect(Log.count).to eq(1)
				end
			end
			response '422', 'invalid format' do
				let(:input) { JSON.parse(file_fixture("test_invalid.csv.json").read) }
				run_test! do
					expect(Store.count).to eq(0)
					expect(Log.count).to eq(0)
				end
			end
			response '422', 'invalid format' do
				let(:input) { JSON.parse(file_fixture("test_valid.json").read) }
				run_test! do
					expect(Store.count).to eq(0)
					expect(Log.count).to eq(0)
				end
			end
		end

		post 'write data' do # write JSON
			before do
				Semantic.destroy_all
				@sem = Semantic.new(validation: file_fixture("init_format_json.trig").read)
				@sem.save!
			end
			tags 'Data access'
			consumes 'application/json'
			parameter name: :input, in: :body
			response '200', 'success' do
				let(:input) { JSON.parse(file_fixture("test_valid.json").read) }
				run_test! do
					expect(Store.count).to eq(6)
					expect(Log.count).to eq(1)
				end
			end
		end

		get 'read data' do
			tags 'Data access'
			produces 'application/json'
			response '200', 'success' do
				run_test! do |response|
					data = JSON.parse(response.body)
					expect(data.length).to eq(2)
					expect(Log.count).to eq(1)
				end
			end
		end

		get 'read data with default output structure' do
			before do
				Semantic.destroy_all
				@sem = Semantic.new(validation: file_fixture("init_format_csv.trig").read)
				@sem.save!
				Store.destroy_all
				@store = Store.new(item: "22332;\"Klagenfurt/Flughafen\";447;\"25-02-2029\";\"25:00\";-2,3;-5,4;73;256;5;268;23,7;0;2022,3;956,8;200")
				@store.save!
				@store = Store.new(item: "22333;\"Klagenfurt/Flughafen\";447;\"25-02-2029\";\"25:00\";-2,3;-5,4;73;256;5;268;23,7;0;2022,3;956,8;200")
				@store.save!
			end
			tags 'Data access'
			produces 'application/json'
			response '200', 'success' do
				run_test! do |response|
					data = JSON.parse(response.body)
					data_parsed = CSV.parse(data["provision"]["content"], col_sep: ";")
					expect(data.length).to eq(2)
					expect(data["provision"]["content"].length).to eq(201)
					expect(data_parsed.length).to eq(2)
					expect(Log.count).to eq(1)
				end
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
			tags 'Data access'
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
