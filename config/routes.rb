Rails.application.routes.draw do
	mount Rswag::Ui::Engine => '/api-docs'
	mount Rswag::Api::Engine => '/api-docs'
	match '/oauth/revoke'           => 'application#revoke_token',        via: 'post'
	use_doorkeeper do
		skip_controllers :applications
	end
	namespace :api, defaults: { format: :json } do
		scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
#			match 'desc', to: 'semantics#create',         via: 'post'
#			match 'desc', to: 'semantics#show',           via: 'get'
#			match 'desc/info', to: 'semantics#show_info', via: 'get'
#			match 'desc/example', to: 'semantics#show_example', via: 'get'
			match 'active',         to: 'processes#active',       via: 'get'
			match 'init',           to: 'processes#init',         via: 'post'
			match 'meta',           to: 'semantics#create',       via: 'post'
			match 'meta',           to: 'semantics#show',	      via: 'get'
			match 'meta/info',      to: 'semantics#show_info',    via: 'get'
			match 'meta/usage',     to: 'semantics#show_usage',   via: 'get'
			match 'meta/example',   to: 'semantics#show_example', via: 'get'
			match 'data',           to: 'stores#index',           via: 'get'
			match 'data/plain',     to: 'stores#plain',           via: 'get'
			match 'data/full',      to: 'stores#full',            via: 'get'
			match 'data/provision', to: 'stores#provision',       via: 'get'
			match 'data',           to: 'stores#write',           via: 'post'
			match 'info',           to: 'infos#index',            via: 'get'
			match 'log',            to: 'logs#index',             via: 'get'
			match 'buy',            to: 'payments#buy',           via: 'post'
			match 'paid',           to: 'payments#paid',          via: 'get'
			match 'payments',       to: 'payments#payments',      via: 'get'

			#watermarking
			match 'data/fragment/:fragment_id', 
				to: 'watermarks#account_fragment',                via: 'get'
			match 'watermark/account/:account_id',
				to: 'watermarks#account_data',                    via: 'get'
			match 'watermark/account/:account_id/fragment/:fragment_id',
				to: 'watermarks#account_fragment_data',           via: 'get'
			match 'watermark/account/:account_id/fragment/:fragment_id/error',
				to: 'watermarks#account_fragment_error',          via: 'get'
			match 'watermark/account/:account_id/fragment/:fragment_id/kpi/:kpi',
				to: 'watermarks#account_fragment_kpi',            via: 'get'
			match 'watermark/error/:key(/:len)',
				to: 'watermarks#key',                             via: 'get'
			match 'watermark/fragments',     
				to: 'watermarks#fragments_list',                  via: 'get'
			match 'watermark/fragment/:fragment_id',     
				to: 'watermarks#raw_data',                        via: 'get'
			match 'watermark/identify', 
				to: 'watermarks#identify',                        via: 'post'
			match 'watermark/account/:account_id/fragment/:fragment_id',
				to: 'watermarks#compare',                         via: 'post'
		end
	end
	match '/oauth/applications'     => 'application#create_application',  via: 'post'
	match '/oauth/applications/:id' => 'application#destroy_application', via: 'delete'
	match ':not_found' => 'application#missing', :constraints => { :not_found => /.*/ }, via: [:get, :post]
end
