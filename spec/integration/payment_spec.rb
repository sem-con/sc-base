# spec/integration/base_spec.rb
# rake rswag:specs:swaggerize

# start billing service in ~/semcon/base/srv-billing
# docker run -d --name srv-billing -p 4800:3000 -v $PWD/tmp:/key --env-file .env semcon/srv-billing
ENV["BILLING_SERVICE"] = "http://localhost:4800"

require 'swagger_helper'

describe 'SEMCON BILLING API' do
	path '/api/buy' do
		post 'buy data' do
			tags 'Billing'
			consumes 'application/json'
			parameter name: :input, in: :body
			response '200', 'success' do
				let(:input) { { "buyer": "christoph.fabianek@gmail.com",
								"buyer-pubkey-id": "D32F87617903542569E19BB992C8EB2354589D87",
								"request": "a=b",
								"signature": "iQIzBAABCgAdFiEE0y+HYXkDVCVp4Zu5ksjrI1RYnYcFAlzS7f8ACgkQksjrI1RYnYemyxAAkqClgWLiZ9QQicyDkiN5+vDDb7W+kSf+5+5QkSXmySCWQRx5mWS5RkB+frbqdpk7+ISqEDDuycbUnAPGtKi6PjZNeUZAuknhFxMwtllCKjUDOJMZ0Nc/afNkH6tx90ODBDdzZ+D30VxCS95fL6cMVc98ZQIWAOr3RCYhM3Pv98OeWmDeuuK0Xw9vpo2zPZCg98r2swn+qhptP8ZmvSLZlYOvmccskxzRGnHVPbYCrpJD3cx4+Z0N5LaUnzfiE8iTyoN0Pw+4HwHyKv2wuZkFlCYnu/bmXImG1e79rKgo6yC5FAaZJR0QWL0x2HGAOTyk4iD2DMb2BjyLYgWBhKqpQN6EEHHYY7V6ow4hPixOmVLk9Xh/4ox5MfpsSMDq1G3gmF4X/VQY3jna8/XWgqkpLUylxL7yFLJEATwszZMjswc/M2crrHG/AWLSEqhtVr+sXxx0jd/Wnap5pueBbBegw1q0WN5x0gxFIylt4pka5jax9Pb1T3rLJXVxdXcdosnDFrNqQiOn74XfEUSGfyXaEd+xh+hnGab4qc+KxptB2LPiwyl4IX+wiAJ6O8UNzo+qbHJ06TdCs6mXev36ZpK1Nb6Lnz2DLKwomtRGZy6d9BkI2KpqR68wkZhx6/pDZGs1Izaqt+D2jfnDrcVVNTPXecpwX92655Yj3etsYpb8iUc=",
								"usage-policy": "@prefix owl: <http://www.w3.org/2002/07/owl#> .\n@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n@prefix spl: <http://www.specialprivacy.eu/langs/usage-policy#> .\n@prefix svd: <http://www.specialprivacy.eu/vocabs/data#> .\n@prefix svr: <http://www.specialprivacy.eu/vocabs/recipients#> .\n@prefix svpu: <http://www.specialprivacy.eu/vocabs/purposes#> .\n@prefix svpr: <http://www.specialprivacy.eu/vocabs/processing#> .\n@prefix svl: <http://www.specialprivacy.eu/vocabs/locations#> .\n@prefix svdu: <http://www.specialprivacy.eu/vocabs/duration#> .\n@prefix svd: <http://www.specialprivacy.eu/vocabs/data#> .\n\n:ContainerPolicy rdf:type owl:Class ; # this line should not be changed!\n    owl:equivalentClass [ \n        owl:intersectionOf ( \n            [ \n                rdf:type owl:Restriction ;\n                owl:onProperty spl:hasData ;\n                owl:someValuesFrom spl:AnyData\n            ]\n            [ \n                rdf:type owl:Restriction ;\n                owl:onProperty spl:hasRecipient ;\n                owl:someValuesFrom spl:AnyRecipient\n            ]\n            [ \n                rdf:type owl:Restriction ;\n                owl:onProperty spl:hasPurpose ;\n                owl:someValuesFrom spl:AnyPurpose\n            ]\n            [ \n                rdf:type owl:Restriction ;\n                owl:onProperty spl:hasProcessing ;\n                owl:someValuesFrom spl:AnyProcessing\n            ]\n            [ \n                rdf:type owl:Restriction ;\n                owl:onProperty spl:hasLocation ;\n                owl:someValuesFrom spl:AnyLocation\n            ]\n            [ \n                rdf:type owl:Restriction ;\n                owl:onProperty spl:hasDuration ;\n                owl:someValuesFrom svdu:StatedPurpose\n            ]\n        ) ;\n        rdf:type owl:Class\n    ] .",
								"method": "ether" } }
				schema type: :object,
					properties: {
						billing: { type: :hash },
						provision: { type: :hash },
						validation: { type: :hash }
					},
				required: [ 'billing', 'provision', 'validation' ]
				run_test! do
				end
			end
		end
	end

	path '/api/paid?tx={transaction_hash}' do
		parameter name: :transaction_hash, in: :path, type: :string
		get 'confirm payment' do
			before do
				Billing.destroy_all
				@bil = Billing.new(uid: "46b1e6d31fdf2faa65f0cef6de9c4d9868f039d6",
								   payment_address: "0xe7a3a048d9851977a9a7deda5b05e8b8708325f1",
								   buyer: "christoph.fabianek@gmail.com",
								   buyer_pubkey_id: "D32F87617903542569E19BB992C8EB2354589D87",
								   offer_price: 0.001)
				@bil.save!
			end
			tags 'Billing'
			produces 'application/json'
			response '200', 'success' do
				let(:transaction_hash) { "0x06bf30b730ead19766d55c0cd3fe6a37a932861eb7fa6d0eaa9c430b9866c876" }
				schema type: :object,
					properties: {
						key: { type: :string },
						secret: { type: :string }
					},
				required: [ 'key', 'secret' ]
				run_test! do
				end
			end
		end
	end

	path '/api/payments' do
		get 'list all payments' do
			tags 'Billing'
			produces 'application/json'
			response '200', 'success' do
				run_test! do
				end
			end
		end
	end
end
