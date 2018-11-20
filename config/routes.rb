Rails.application.routes.draw do
	use_doorkeeper
	namespace :api, defaults: { format: :json } do
		scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
			match 'desc', to: 'semantics#create',         via: 'post'
			match 'desc', to: 'semantics#show',           via: 'get'
			match 'desc/info', to: 'semantics#show_info', via: 'get'
			match 'desc/example', to: 'semantics#show_example', via: 'get'
			match 'data', to: 'stores#index',             via: 'get'
			match 'data', to: 'stores#create',            via: 'post'
		end
	end
end
