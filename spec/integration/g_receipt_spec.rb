# spec/integration/g_receipt_spec.rb
# rake rswag:specs:swaggerize

require 'swagger_helper'

describe 'SEMCON RECEIPT API' do
	path '/api/receipts' do
		get 'get all receipts for container' do
			tags 'Data receipt'
			produces 'application/json'
			response '200', 'success' do
				schema type: :array
				run_test!
			end
		end
	end

	path '/api/receipt/{id}' do
		get 'retrieve information for specified receipt (including record IDs)' do
			tags 'Data receipt'
			produces 'application/json'
			parameter name: :id, in: :path, type: :string,
				description: "hash value provided by write operation"
			response '200', 'success' do
				run_test!
			end
			response '404', 'not found' do
				run_test!
			end
		end
	end

	path '/api/receipt/{ttl}/{id}' do
		get 'retrieve complete information for specified receipt with maximum recursion level defined in ttl (time-to-live)' do
			tags 'Data receipt'
			produces 'application/json'
			parameter name: :ttl, in: :path, type: :integer,
				description: "recursion level to query subsequent containers"
			parameter name: :id, in: :path, type: :string,
				description: "hash value provided by write operation"
			response '200', 'success' do
				run_test!
			end
			response '404', 'not found' do
				run_test!
			end
		end
	end

	path '/api/receipt/{id}/revoke' do
		delete 'revoke all records for specified receipt' do
			tags 'Data receipt'
			produces 'application/json'
			parameter name: :id, in: :path, type: :string,
				description: "hash value provided by write operation"
			consumes 'application/json'
			parameter name: :input, in: :body,
				description: "complete original receipt"
			response '200', 'success' do
				run_test!
			end
			response '404', 'not found' do
				run_test!
			end			
		end
	end

	path '/api/rcpt/{id}' do
		get 'retrieve abbreviated information for specified receipt (without record IDs)' do
			tags 'Data receipt'
			produces 'application/json'
			parameter name: :id, in: :path, type: :string,
				description: "hash value provided by write operation"
			response '200', 'success' do
				run_test!
			end
			response '404', 'not found' do
				run_test!
			end
		end
	end

	path '/api/rcpt/{ttl}/{id}' do
		get 'retrieve abbreviated information for specified receipt with maximum recursion level defined in ttl (time-to-live)' do
			tags 'Data receipt'
			produces 'application/json'
			parameter name: :ttl, in: :path, type: :integer,
				description: "recursion level to query subsequent containers"
			parameter name: :id, in: :path, type: :string,
				description: "hash value provided by write operation"
			response '200', 'success' do
				run_test!
			end
			response '404', 'not found' do
				run_test!
			end
		end
	end

	path '/api/receipt/{hash}' do
		post 'store receipt data for write request' do
			tags 'Data receipt'
			consumes 'application/json'
			parameter name: :hash, in: :path, type: :string,
				description: "hash value of retrieved data"
			parameter name: :input, in: :body,
			    description: "receipt JSON provided by write operation"
			response '200', 'success' do
				run_test!
			end
			response '404', 'not found' do
				run_test!
			end
		end
	end	

end