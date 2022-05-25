class ApplicationController < ActionController::API
    before_action -> { doorkeeper_authorize! :admin }, only: [:create_application, :destroy_application]
    before_action :cors_preflight_check
    after_action :cors_set_access_control_headers
    
    include ActionController::MimeResponds
    include ApplicationHelper

    def cors_preflight_check
        if request.method == 'OPTIONS'
            headers['Access-Control-Allow-Origin'] = '*'
            headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
            headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, Token'
            headers['Access-Control-Max-Age'] = '1728000'
            headers['Access-Control-Expose-Headers'] = '*'

            render text: '', content_type: 'text/plain'
        end
    end

    def cors_set_access_control_headers
        headers['Access-Control-Allow-Origin'] = '*'
        headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
        headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, Token'
        headers['Access-Control-Max-Age'] = "1728000"
        headers['Access-Control-Expose-Headers'] = '*'
    end

    def doorkeeper_unauthorized_render_options(error: nil)
        { json: { error: "Not authorized" } }
    end

    def doorkeeper_forbidden_render_options(*)
        { json: { error: "Not authorized" } }
    end


    def revoke_token
        token = Doorkeeper::AccessToken.find_by_token(params[:token].to_s)
        if token.nil?
            render json: {"error": "token not found"},
                   status: 404
        else
            token.destroy
            render plain: "",
                   status: 200
        end
    end

    def create_application
        new_app = Doorkeeper::Application.new(
            name: params[:name].to_s,
            redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
            scopes: params[:scopes].to_s,
            sc_query: params[:query],
            oidc_identifier: params[:oidc_identifier],
            oidc_secret: params[:oidc_secret],
            oidc_token_endpoint: params[:oidc_token_endpoint])
        if new_app.save
            createLog({"type": "new app","scope": "id: " + new_app.id.to_s + ", name: '" + params[:name].to_s + "', scopes: '" + params[:scopes].to_s + "'" })
            render json: { id: new_app.id,
                           name: new_app.name,
                           client_id: new_app.uid,
                           client_secret: new_app.secret,
                           scopes: new_app.scopes }.to_json,
                   status: 200
        else
            render json: { error: new_app.errors.full_messages.to_s }.to_json,
                   status: 500
        end
    end

    def destroy_application
        app = Doorkeeper::Application.find(params[:id]) rescue nil
        if app.nil?
            render json: { "error": "application not found" }.to_json,
                   status: 404
        else
            app.destroy
            createLog({"type": "destroy app","scope": "id: " + params[:id].to_s })
            render json: { id: params[:id] }.to_json,
                   status: 200
        end
    end

    def oidc
        begin
            code = params[:code].to_s
            state = params[:state].to_s
            redirect_uri = params[:redirect_uri].to_s
            application_id = params[:application_id].to_i rescue 0
            puts "Code: " + code
            puts "State: " + state
            puts "Redirect URI: " + redirect_uri
            puts "Application-ID: " + application_id.to_s

            @app = Doorkeeper::Application.find(application_id)
            if @app.nil?
                render json: {"error": "invalid application_id"},
                       status: 500
                return
            end
            endpoint_url = @app.oidc_token_endpoint.to_s
            oidc_identifier = @app.oidc_identifier.to_s
            oidc_secret = @app.oidc_secret.to_s

            token_url = endpoint_url + "?"
            token_url += "grant_type=id_token&"
            token_url += "code=" + code + "&"
            token_url += "redirect_uri=" + redirect_uri + "&"
            token_url += "client_id=" + oidc_identifier + "&"
            token_url += "client_secret=" + oidc_secret

            timeout = false
            begin
                response = HTTParty.post(token_url, timeout: 15)
            rescue
                timeout = true
            end
            if timeout or response.nil? or response.code != 200
                response_code = response.code rescue 500
                render json: {"error": "OIDC token request failed"}, 
                       status: response_code
                return
            end

            id_token = response.parsed_response["id_token"]
            access_token = response.parsed_response["access_token"] rescue ""
            expires_in = response.parsed_response["expires_in"].to_i rescue 60
            decoded_token = JWT.decode id_token, nil, false
            user = decoded_token.first["sub"]
            entitlements = decoded_token.first["entitlements"]

            @oauth = Doorkeeper::Application.find(application_id)
            @t = Doorkeeper::AccessToken.new(
                    application_id: @oauth.id, 
                    expires_in: expires_in * 60, 
                    scopes: @oauth.scopes)

            if @t.save
                @t.update_attributes(token: access_token)
                render json:  { access_token: access_token,
                                token_type: "Bearer",
                                expires_in: expires_in * 60,
                                scope: @oauth.scopes,
                                created_at: Time.now.to_i }, 
                       status: 200
            else
                render json: {"error": "cannot create access token"},
                       status: 500
            end
        rescue Exception => e
            render json: {"error": "#{e}"},
                   status: 500
        end
    end

    def missing
        render json: {"error": "invalid path"},
               status: 404
    end

end
