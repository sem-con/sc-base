# spec/integration/usage_spec.rb

require 'swagger_helper'

describe 'SEMCON USAGE API' do
	path '/api/data' do
		post 'write data' do # test usage policy + writing RDF
			before do
				Semantic.destroy_all
				@sem = Semantic.new(validation: file_fixture("init.trig").read)
				@sem.save!
			end
			tags 'Basic'
			consumes 'application/json'
			parameter name: :input, in: :body
			response '200', 'success' do
				let(:input) { JSON.parse(file_fixture("data_usage.json").read) }
				run_test! do
					expect(Store.count).to eq(2)
					expect(Log.count).to eq(1)
				end
			end
			response '412', 'non-matching usage policy' do
				let(:input) { JSON.parse(file_fixture("data_invalid-usage.json").read) }
				run_test! do
					expect(Store.count).to eq(0)
					expect(Log.count).to eq(1)
				end
			end				
			response '500', 'invalid input' do
				let(:input) { "" }
				run_test!
			end
		end
	end

end