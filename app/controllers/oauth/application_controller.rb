class Oauth::ApplicationController < Doorkeeper::ApplicationsController
    before_action -> { doorkeeper_authorize! :admin }
end