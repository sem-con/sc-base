module Api
    module V1
        class PaymentsController < ApiController
            require 'securerandom'
            include ApplicationHelper
            include DataAccessHelper
            include ProvenanceHelper
            include PaymentHelper
            # include PayPal::SDK::REST

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def payments
                render json: Billing.all,
                       status: 200
            end

            def buy
                retVal = {}
                buyer = params["buyer"].to_s
                buyer_pubkey_id = params["buyer-pubkey-id"].to_s
                buyer_info = params["buyer-info"].to_s
                request_str = params["request"].to_s
                signature = params["signature"].to_s
                usage_policy = params["usage-policy"].to_s
                payment_method = params["payment-method"].to_s

                # checks ===
                # check valid payment method
                if payment_method.downcase != "ether"
                    render json: {"error": "unsupported payment method"}, 
                           status: 412
                    return
                end

                # verify signature ===
                # call srv-billing: verify(doc, doc.sig, email, pubkey-id)
                billing_service_url = payment_billing_service_url
                signature_verification_url = billing_service_url + "/api/verify"
                signature_verification_body = {
                    "email": buyer,
                    "pubkey-id": buyer_pubkey_id,
                    "original": request_str,
                    "signature": signature
                }.stringify_keys
                timeout = false
                begin
                    response = HTTParty.post(signature_verification_url, 
                        timeout: 15,
                        headers: { 'Content-Type' => 'application/json' },
                        body: signature_verification_body.to_json)
                rescue
                    timeout = true
                end

                if timeout or response.nil? or response.code != 200
                    response_code = response.code rescue 500
                    render json: {"error": "signature verification failed"}, 
                           status: response_code
                    return
                end
                if response.parsed_response["valid"].to_s.downcase != "true"
                    render json: {"error": "signature does not match request"}, 
                           status: 412
                    return
                end

                # get price ===
                get_price_url = billing_service_url + "/api/payment_terms"
                get_price_body = {
                    "request": request_str,
                    "usage-policy": usage_policy,
                    "method": payment_method
                }.stringify_keys
                response = HTTParty.post(get_price_url, 
                    headers: { 'Content-Type' => 'application/json' },
                    body: get_price_body.to_json)
                if response.code != 200
                    render json: {"error": "retrieving price failed"}, 
                           status: response.code
                    return
                end

                if response.parsed_response["valid"].to_s.downcase != "true"
                    render json: {"error": response.parsed_response["offer-info"].to_s}, 
                           status: 412
                    return
                end
                price = response.parsed_response["price"].to_f rescue 0
                offer_info = response.parsed_response["offer-info"].to_s rescue ""
                offer_end = Time.at(response.parsed_response["offer-end"].to_i).to_datetime rescue Time.now+30.days

                # get payment infos ===
                payment_infos_url = billing_service_url + "/api/payment_info"
                payment_infos = HTTParty.get(payment_infos_url)
                if response.code != 200
                    render json: {"error": "failed to collect payment infos"}, 
                           status: response.code
                    return
                end
                address_path = payment_infos["path"].to_s rescue ""

                # write to model billing ===
                bil = Billing.new(
                    uid: SecureRandom.hex(20).to_s,
                    buyer: buyer,
                    buyer_pubkey_id: buyer_pubkey_id,
                    buyer_info: buyer_info,
                    buyer_signature: signature,
                    offer_price: price,
                    offer_timestamp: Time.now,
                    offer_info: offer_info,
                    valid_until: offer_end,
                    payment_address: payment_infos["address"].to_s,
                    payment_method: payment_method,
                    address_path: address_path,
                    request: request_str,
                    seller: payment_info["email"].to_s,
                    seller_pubkey_id: payment_infos["pubkey-id"].to_s,
                    usage_policy: usage_policy)
                if !bil.save
                    render json: {"error": "saving payment request failed"}, 
                           status: 500
                    return
                end

                # create signature ===
                # call srv-billing: sign request string
                create_signature_url = billing_service_url + "/api/sign"
                create_signature_body = {
                    "data": Base64.strict_encode64(bil.uid).to_s,
                }.stringify_keys
                response = HTTParty.post(create_signature_url, 
                    headers: { 'Content-Type' => 'application/json' },
                    body: create_signature_body.to_json)
                if response.code != 200
                    render json: {"error": "signing ID failed"}, 
                           status: response.code
                    return
                end
                seller_signature = response.parsed_response["signature"].to_s

                # update billing record
                if !bil.update_attributes(seller_signature: seller_signature)
                    render json: {"error": "updating payment request failed"}, 
                           status: 500
                    return
                end

                # build response ===
                billing = {
                    "uid": bil.uid,
                    "signature": bil.seller_signature,
                    "provider": bil.seller,
                    "provider-pubkey-id": bil.seller_pubkey_id,
                    "offer-timestamp": bil.offer_timestamp,
                    "offer-info": bil.offer_info,
                    "payment-method": "Ether",
                    "payment-address": bil.payment_address,
                    "cost": bil.offer_price,
                    "payment-info": payment_info
                }.stringify_keys

                billing_hash = Digest::SHA256.hexdigest(billing.to_json)
                param_str = request.query_string.to_s
                timeStart = Time.now.utc
                timeEnd = Time.now.utc

                provision = {
                    "usage-policy": container_usage_policy.to_s,
                    "provenance": getProvenance(billing_hash, param_str, timeStart, timeEnd)
                }.stringify_keys
                provision_hash = Digest::SHA256.hexdigest(billing.to_json + ", " + provision.to_json)

                begin
                    response = HTTParty.post("https://blockchain.ownyourdata.eu/api/doc?hash=" + provision_hash.to_s)
                rescue => ex
                    response = nil
                end

                dlt_reference = ""
                if !response.nil? && response.code.to_s == "200"
                    if response.parsed_response["address"] == ""
                        dlt_reference = "https://notary.ownyourdata.eu/en?hash=" + provision_hash.to_s
                    else
                        dlt_reference = {
                            "dlt": "Ethereum",
                            "address": response.parsed_response["address"],
                            "audit-proof": response.parsed_response["audit-proof"]
                        }.stringify_keys
                    end
                end

                retVal = {
                    "billing": billing,
                    "provision": provision,
                    "validation": {
                        "hash": provision_hash,
                        "dlt-reference": dlt_reference
                    }
                }.stringify_keys

                render json: retVal.to_json, 
                       status: 200
            end

            def paid
                if params["buyer-identification"].to_s == "A-Trust"
                    # validate input ===

                    # validate signature
                    # request to srv-eidas for verification of params["buyer-signature"]
                    sig_validation_url = ENV["EIDAS_URL"] + "/api/verify"
                    sig_string = '<?xml version="1.0" encoding="UTF-8"?><sl:VerifyCMSSignatureRequest xmlns:sl="http://www.buergerkarte.at/namespaces/securitylayer/1.2#"><sl:CMSSignature>'
                    sig_string += params["buyer-signature"].to_s
                    sig_string += '</sl:CMSSignature></sl:VerifyCMSSignatureRequest>'
                    sig_string = CGI.escape sig_string
                    retVal = HTTParty.post(sig_validation_url, 
                        headers: { 'Content-Type' => 'application/json' },
                        body: {"value": sig_string}.to_json)
                    if retVal.code == 200
                        buyer_info = retVal.parsed_response["VerifyCMSSignatureResponse"]["SignerInfo"]["X509Data"]["X509SubjectName"] rescue ""
                        if buyer_info == ""
                            render json: {"error": "missing buyer information"},
                                   status: 500
                            return
                        end
                    else
                        render json: {"error": "invalid signature"},
                               status: 500
                        return
                    end

                    # validate PayPal ID with params["payment-id"]
                    token = PayPal::SDK::REST.set_config(
                        mode: ENV['PAYPAL_ENV'], 
                        client_id: ENV['PAYPAL_CLIENT_ID'], 
                        client_secret: ENV['PAYPAL_CLIENT_SECRET'], 
                        ssl_options: { ca_file: nil }).token
                    order_id = JSON.parse(params["payment-info"])["id"].to_s rescue ""
                    bil_validation_url = "https://api.sandbox.paypal.com/v2/checkout/orders/"
                    retVal = HTTParty.get(
                        bil_validation_url + order_id,
                        headers: { 'Content-Type' => 'application/json', 'Authorization' => 'Bearer ' + token})
                    if retVal.code == 200
                        if retVal.parsed_response["status"] != "COMPLETED"
                            render json: {"error": "invalid PayPal status"},
                                   status: 500
                            return
                        end
                    else
                        render json: {"error": "invalid PayPal Order ID"},
                               status: 500
                        return
                    end
                    address_info = retVal.parsed_response["purchase_units"].first["shipping"]["address"].to_json
                    payment_price = retVal.parsed_response["purchase_units"].first["payments"]["captures"].first["amount"]["value"].to_f rescue nil
                    payment_timestamp = retVal.parsed_response["update_time"].to_s rescue nil
                    transaction_timestamp = retVal.parsed_response["create_time"].to_s rescue nil

                    # create Billing record ===
                    @bil = Billing.find_by_uid(params["uid"].to_s)
                    if @bil.nil?
                        bil = Billing.new(
                            uid: params["uid"].to_s,
                            buyer: params["buyer"].to_s,
                            buyer_info: buyer_info,
                            buyer_signature: params["buyer-signature"].to_s,
                            buyer_pubkey_id: nil,
                            buyer_address: address_info,
                            offer_price: params["cost"].to_f,
                            offer_timestamp: transaction_timestamp,
                            offer_info: params["records"].to_s +  " records",
                            valid_until: params["valid-until"].to_s,
                            payment_address: nil,
                            payment_method: "PayPal",
                            payment_price: payment_price,
                            payment_timestamp: payment_timestamp,
                            address_path: nil,
                            request: params["request"].to_json,
                            seller: "ZAMG",
                            seller_pubkey_id: nil,
                            transaction_hash: order_id.to_s,
                            transaction_timestamp: Time.now,
                            usage_policy: params["usage-policy"].to_s)
                        if !bil.save
                            render json: {"error": "saving payment request failed"}, 
                                   status: 500
                            return
                        end
                    else
                        @bil.update_attributes(
                            transaction_timestamp: Time.now)
                    end

                    # return data  ===
                    retVal = getData(params["request"])

                    render json: retVal,
                           status: 200
                    return
                else
                    # === handle payment with Ether ===
                    billing_service_url = payment_billing_service_url

                    # parse input parameters ===
                    tx = params[:tx].to_s
                    if tx[0..1] != "0x"
                        tx = "0x" + tx
                    end

                    # check transaction ===
                    check_transaction_url = billing_service_url + "/api/transaction?tx=" + tx
                    response = HTTParty.get(check_transaction_url)
                    if response.code != 200
                        render json: {"error": "retrieving transaction failed"}, 
                               status: response.code
                        return
                    end
                    uid = response.parsed_response["input"].to_s
                    address = response.parsed_response["to"].to_s
                    price = response.parsed_response["value"].to_f
                    ts = response.parsed_response["timestamp"].to_i rescue 0

                    if uid[0..1] == "0x"
                        uid = uid[2..-1]
                    end

                    # bil = Billing.first
                    bil = Billing.find_by_uid(uid)
                    if bil.nil?
                        render json: {"error": "invalid transaction input"}, 
                               status: 412
                        return
                    end
                    
                    if address.downcase != bil.payment_address.to_s.downcase
                        render json: {"error": "invalid payment address"}, 
                               status: 412
                        return
                    end

                    if price < bil.offer_price
                        render json: {"error": "not enough funds"}, 
                               status: 412
                        return
                    end

                    if ts > bil.valid_until.to_i
                        bil.update_attributes(
                            transaction_hash: tx,
                            transaction_timestamp: Time.at(ts))
                        render json: {"error": "offer expired"}, 
                               status: 412
                        return
                    end

                    # update billing record ===
                    bil.update_attributes(
                        buyer_address: response.parsed_response["from"].to_s,
                        payment_price: price,
                        payment_timestamp: Time.now, 
                        transaction_hash: tx,
                        transaction_timestamp: Time.at(ts))

                    # create OAuth credentials ===
                    oauth = Doorkeeper::Application.new( 
                        name: bil.uid, 
                        redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                        scopes: 'read')
                    if !oauth.save
                        render json: {"error": "creating oauth credentials failed"}, 
                               status: 412
                        return
                    end

                    # encrypt secret with pubkey ===
                    encrypt_url = billing_service_url + "/api/encrypt"
                    encrypt_body = {
                        "email": bil.buyer.to_s,
                        "pubkey-id": bil.buyer_pubkey_id.to_s,
                        "message": Base64.strict_encode64(oauth.secret.to_s)
                    }.stringify_keys
                    response = HTTParty.post(encrypt_url, 
                        headers: { 'Content-Type' => 'application/json' },
                        body: encrypt_body.to_json)
                    if response.code != 200
                        render json: {"error": "encrypting oauth secret failed"}, 
                               status: response.code
                        return
                    end
                    oauth_secret = response.parsed_response["cipher"]

                    retVal = {
                        "key": oauth.uid.to_s,
                        # "secret": oauth.secret.to_s
                        "secret": oauth_secret.to_s
                    }.stringify_keys

                    render json: retVal.to_json, 
                           status: 200
                end
            end
        end
    end
end