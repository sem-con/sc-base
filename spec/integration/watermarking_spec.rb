# spec/integration/watermarking_spec.rb
# rake rswag:specs:swaggerize

require 'swagger_helper'

describe 'SEMCON WATERMARKING API' do
	path '/api/data/fragment/{id}' do
		get 'apply watermarking to data' do
			tags 'Watermarking'
			produces 'application/json'
			parameter name: :id, in: :path, type: :string,
				description: "identification ('id') for watermarked data fragment"
			response '200', 'success' do
				let(:id) { '1' }
				run_test!
			end
			response '404', 'not found' do
				let(:id) { '0' }
				run_test!
			end
		end
	end

	path '/api/watermark/account/{account_id}' do
		get 'get watermarked data for given account' do
			tags 'Watermarking'
			produces 'application/json'
			parameter name: :account_id, in: :path, type: :integer,
				description: "identification for account within container (requires key & secret)"
			response '200', 'success' do
				let(:acount_id) { '1' }
				run_test!
			end
			response '404', 'not found' do
				let(:acount_id) { '1' }
				run_test!
			end
		end
	end

	path '/api/watermark/account/{account_id}/fragment/{fragment_id}' do
		get 'get specified watermarked data fragment for given account' do
			tags 'Watermarking'
			produces 'application/json'
			parameter name: :account_id, in: :path, type: :integer,
				description: "identification for account within container (requires key & secret)"
			parameter name: :fragment_id, in: :path, type: :integer,
				description: "identification ('id') for watermarked data fragment"
			response '200', 'success' do
				let(:acount_id) { '1' }
				let(:fragment_id) { '1' }
				run_test!
			end
			response '404', 'not found' do
				let(:acount_id) { '1' }
				let(:fragment_id) { '1' }
				run_test!
			end
		end
	end

	path '/api/watermark/account/{account_id}/fragment/{fragment_id}/error' do
		get 'get error vector for specified watermarked data fragment and given account' do
			tags 'Watermarking'
			produces 'application/json'
			parameter name: :account_id, in: :path, type: :integer,
				description: "identification for account within container (requires key & secret)"
			parameter name: :fragment_id, in: :path, type: :integer,
				description: "identification ('id') for watermarked data fragment"
			response '200', 'success' do
				let(:acount_id) { '1' }
				let(:fragment_id) { '1' }
				run_test!
			end
			response '404', 'not found' do
				let(:acount_id) { '1' }
				let(:fragment_id) { '1' }
				run_test!
			end
		end
	end

	path '/api/watermark/account/{account_id}/fragment/{fragment_id}/kpi/{kpi}' do
		get 'get KPIs for specified watermarked data fragment and given account' do
			tags 'Watermarking'
			produces 'application/json'
			parameter name: :account_id, in: :path, type: :integer,
				description: "identification for account within container (requires key & secret)"
			parameter name: :kpi, in: :path, type: :string,
				description: "'mean' for arithmetic mean and 'stdv' for standard deviation"
			response '200', 'success' do
				let(:acount_id) { '1' }
				let(:fragment_id) { 1 }
				let(:kpi) { 'mean' }
				run_test!
			end
			response '404', 'not found' do
				let(:acount_id) { '1' }
				let(:fragment_id) { 1 }
				let(:kpi) { 'mean' }
				run_test!
			end
		end
	end

	path '/api/watermark/error/{key}' do
		get 'get error vector of length 100 for specified key' do
			tags 'Watermarking'
			produces 'application/json'
			parameter name: :key, in: :path, type: :integer,
				description: "numerical input (seed) that generates random error vector"
			response '200', 'success' do
				let(:key) { 1 }
				run_test!
			end
			response '404', 'not found' do
				let(:key) { 1 }
				run_test!
			end
		end
	end

	path '/api/watermark/error/{key}/{len}' do
		get 'get error vector of length "len" for specified key' do
			tags 'Watermarking'
			produces 'application/json'
			parameter name: :key, in: :path, type: :integer,
				description: "numerical input (seed) that generates random error vector"
			parameter name: :key, in: :path, type: :integer,
				description: "define length of error vector"
			response '200', 'success' do
				let(:key) { 1 }
				let(:length) { 200 }
				run_test!
			end
			response '404', 'not found' do
				let(:key) { 1 }
				let(:length) { 200 }
				run_test!
			end
		end
	end

	path '/api/watermark/fragments' do
		get 'get list of fragment identifiers, associated keys, and account_id' do
			tags 'Watermarking'
			produces 'application/json'
			response '200', 'success' do
				run_test!
			end
			response '404', 'not found' do
				run_test!
			end
		end
	end	

	path '/api/watermark/fragment/{fragment_id}' do
		get 'get specified (not watermarked) data fragment' do
			tags 'Watermarking'
			produces 'application/json'
			parameter name: :fragment_id, in: :path, type: :integer,
				description: "identification ('id') for watermarked data fragment"
			response '200', 'success' do
				run_test!
			end
			response '404', 'not found' do
				run_test!
			end
		end
	end	

	path '/api/watermark/identify' do
		post 'get descending sorted list of fragment identifiers for provided dataset' do
			tags 'Watermarking'
			consumes 'application/json'
			parameter name: :input, in: :body
			produces 'application/json'
			response '200', 'success' do
				let(:input) { [] }
				run_test!
			end
			response '422', 'invalid format' do
				let(:input) { JSON.parse(file_fixture("test_invalid.csv.json").read) }
				run_test! do
					expect(Store.count).to eq(0)
					expect(Log.count).to eq(0)
				end
			end
			response '500', 'error' do
				let(:input) { [] }
				run_test!
			end
		end
	end

	path '/api/watermark/account/{account_id}/fragment/{fragment_id}' do
		post 'get distance and similarity for given account, fragment_id, and provided dataset' do
			tags 'Watermarking'
			consumes 'application/json'
			parameter name: :input, in: :body
			parameter name: :account_id, in: :path, type: :integer,
				description: "identification for account within container (requires key & secret)"
			parameter name: :fragment_id, in: :path, type: :integer,
				description: "identification ('id') for watermarked data fragment"
			produces 'application/json'
			response '200', 'success' do
				run_test!
			end
			response '422', 'invalid format' do
				run_test!
			end
			response '500', 'error' do
				run_test!
			end
		end
	end
end
