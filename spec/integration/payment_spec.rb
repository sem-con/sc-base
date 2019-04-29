# spec/integration/base_spec.rb
# rake rswag:specs:swaggerize

require 'swagger_helper'

describe 'SEMCON BILLING API' do
	path '/api/buy' do
		post 'buy data' do
			tags 'Billing'
			consumes 'application/json'
			parameter name: :input, in: :body
			response '200', 'success' do
				let(:input) { [{ "asdf": "qwer" }] }
				run_test! do
					expect(Log.count).to eq(0)
				end
			end
			# response '500', 'invalid input' do
			# 	let(:input) { "" }
			# 	run_test!
			# end
		end
	end

	path '/api/paid' do
		get 'confirm payment' do
			tags 'Billing'
			produces 'application/json'
			response '200', 'success' do
				run_test! do
					expect(Log.count).to eq(0)
				end
			end
		end
	end
end
