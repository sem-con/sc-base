# spec/integration/provenance_spec.rb
# rake rswag:specs:swaggerize

require 'swagger_helper'

describe 'SEMCON PROVENANCE API' do
	path '/api/data' do
		get 'check provenance' do
			before do
				Semantic.destroy_all
				@sem = Semantic.new(validation: file_fixture("init_seismic.trig").read)
				@sem.save!
			end
			tags 'Container information'
			produces 'application/json'
			response '200', 'success' do
				schema type: :object,
					properties: {
						provision: { type: :hash },
						validation: { type: :hash }
					},
				required: [ 'provision', 'validation' ]
				run_test! do |response|
					retVal = JSON.parse(response.body)
					expect(retVal["provision"]["provenance"].split("\n").length).to eq(20)
				end
			end
		end
	end

end