Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
	use_doorkeeper
	namespace :api, defaults: { format: :json } do
		scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
#			match 'desc', to: 'semantics#create',         via: 'post'
#			match 'desc', to: 'semantics#show',           via: 'get'
#			match 'desc/info', to: 'semantics#show_info', via: 'get'
#			match 'desc/example', to: 'semantics#show_example', via: 'get'
			match 'init', to: 'processes#init',             via: 'post'
			match 'data', to: 'stores#index',             via: 'get'
			match 'data', to: 'stores#create',            via: 'post'
			match 'info', to: 'infos#index',              via: 'get'
			match 'log',  to: 'logs#index',               via: 'get'
		end
	end
end
