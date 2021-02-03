module Api
    module V1
        class OydidsController < ApiController
            skip_before_action :authentication_check, only: [:init, :token]

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def init
                challenge = SecureRandom.alphanumeric(32)
                @oauth_app = Doorkeeper::Application.find_by_name(params[:public_key]) rescue nil
                if @oauth_app.nil?
                    render json: {"error": "public key not found"},
                           status: 404
                    return
                end
                DidSession.new(
                    session: params[:session_id].to_s,
                    challenge: challenge,
                    oauth_application_id: @oauth_app.id).save
                render json: {"challenge": challenge}, 
                       status: 200
            end

            def token
                #input
                sid = params[:session_id].to_s
                signed_challenge = params[:signed_challenge].to_s

                # checks
                @ds = DidSession.find_by_session(sid)
                if @ds.nil?
                    render json: {"error": "session id not found"},
                           status: 404
                    return
                end
                @oauth = Doorkeeper::Application.find(@ds.oauth_application_id)
                if @oauth.nil?
                    render json: {"error": "OAuth reference not found"},
                           status: 404
                    return
                end
                pubKey = Ed25519::VerifyKey.new(Base58.base58_to_binary(@oauth.name.to_s))
                if !signature_verification(pubKey, Base58.base58_to_binary(signed_challenge), @ds.challenge)
                    render json: {"error": "invalid signature"},
                           status: 403
                    return
                end

                # create token
                @t = Doorkeeper::AccessToken.new(application_id: @oauth.id, expires_in: 7200, scopes: @oauth.scopes)
                if @t.save
                    retVal = {
                        "access_token": @t.token.to_s,
                        "token_type": "Bearer",
                        "expires_in": @t.expires_in,
                        "scope": @t.scopes.to_s,
                        "created_at": @t.created_at.to_i }
                    if !@oauth.sc_query.nil?
                        retVal["query"] = @oauth.sc_query.to_s
                    end
                    render json: retVal,
                           status: 200
                else
                    render json: {"error": "cannot create access token - " + @t.errors.to_json},
                           status: 500
                end
            end

            private
            def signature_verification(key, sig, body)
                begin
                    key.verify(sig, body)
                    return true
                rescue Ed25519::VerifyError
                    return false
                end
            end
        end
    end
end
