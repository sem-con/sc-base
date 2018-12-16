# spec/integration/base_spec.rb

require 'swagger_helper'

describe 'SEMCON BASE API' do
	path '/api/info' do
		get 'container overview' do
			tags 'Basic'
			produces 'application/json'
			response '200', 'success' do
				schema type: :object,
					properties: {
						title: { type: :sting },
						image: { type: :sting },
						records: { type: :integer }
					},
				required: [ 'records' ]
				run_test!
			end
		end
	end

	path '/api/data' do
		get 'read data' do
			tags 'Basic'
			produces 'application/json'
			response '200', 'success' do
				run_test! do |response|
					data = JSON.parse(response.body)
					expect(data.length).to eq(0)
					expect(Log.count).to eq(1)
				end
			end
		end
		post 'write data' do
			tags 'Basic'
			consumes 'application/json'
			parameter name: :input, in: :body
			response '200', 'success' do
				let(:input) { [{ "asdf": "qwer", "ycxv": 4.2 }, { "asdf": "qwer", "ycxv": 4.2 }] }
				run_test! do
					expect(Store.count).to eq(2)
					expect(Log.count).to eq(1)
				end
			end
			response '500', 'not an array' do
				let(:input) { { "asdf": "qwer", "ycxv": 4.2 } }
				run_test!
			end
		end
	end

	path '/api/log' do
		get 'log information' do
			tags 'Basic'
			produces 'application/json'
			response '200', 'success' do
				run_test! do |response|
					expect(Log.count).to eq(0)
					data = JSON.parse(response.body)
					expect(data.count).to eq(0)
				end
			end
		end
	end
end