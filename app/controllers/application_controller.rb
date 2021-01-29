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
            scopes: params[:scopes].to_s)
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

    def missing
        render json: {"error": "invalid path"},
               status: 404
    end

end
