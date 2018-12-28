class Oauth::ApplicationController < Doorkeeper::ApplicationsController
	before_filter :doorkeeper_authorize! :admin
end