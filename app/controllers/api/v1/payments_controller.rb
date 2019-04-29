module Api
    module V1
        class PaymentsController < ApiController
            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def buy
                retVal = {}
                buyer = params["buyer"]

                # parse input parameters ===
                # puts "INPUT -------------------"
                # puts "Buyer: " + buyer.to_s
                # puts params.to_s
                # puts "-------------------------"

                # verify signature ===
                # call srv-billing: verify(doc, doc.sig, email, pubkey-id)

                # get price ===
                # call srv-billing: get_price(request, usage-policy, method)

                # get payment infos ===
                # call srv-billing: get_payment_info()
                #   returns: Ethereum address, seller email, seller pubkey-id

                # get signature ===
                # call srv-billing: sign request string

                # write to model billing ===

                # build response ===
                bil = Billing.first
                if !bil.nil?
                    retVal = {
                        "uid": bil.uid,
                        "seller": bil.seller,
                        "seller-pubkey-id": bil.seller_pubkey_id,
                        "offer-timestamp": bil.offer_timestamp,
                        "cost": bil.price,
                        "payment-address": bil.payment_address,
                        "signature": bil.seller_signature
                    }.stringify_keys
                else
                    retVal = {}
                end

                render json: retVal.to_json, 
                       status: 200
            end

            def paid
                # parse input parameters ===
                # uid = params[:uid]
                # tx = params[:tx]

                # check transaction ===
                # get price via uid in billings
                # call srv-billing check_tx(tx, price)

                # update billing record ===

                # create OAuth credentials ===
                # scope: read & request string

                # sign secret with pubkey ===
                # call srv-billing encrypt(pubkey-id, secret)

                retVal = {
                    "key": "app_key",
                    "secret": "app_secret"
                }.stringify_keys

                render json: retVal.to_json, 
                       status: 200
            end
        end
    end
end