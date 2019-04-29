#!/usr/bin/env ruby
# encoding: utf-8

require 'httparty'
require 'linkeddata'
require 'rdf'

config_raw = ARGV.pop.dup.to_s.force_encoding("utf-8")

init_url = "http://localhost:3000/api/init"
if config_raw.to_s == ""
	response = HTTParty.post(init_url + "?run=1")
else
	response = HTTParty.post(init_url)
end

headers = { 'Content-Type' => 'application/json' }
if ENV["AUTH"] != ""
	# get APP_KEY & APP_SECRET
	app_key = `echo 'Doorkeeper::Application.first.uid' | rails c`.scan(/\h+/).last
	app_secret = `echo 'Doorkeeper::Application.first.secret' | rails c`.scan(/\h+/).last
	auth_url = "http://localhost:3000/oauth/token"
	begin
		response = HTTParty.post(auth_url,
			headers: headers,
	                body: { client_id: app_key, 
	                    client_secret: app_secret, 
	                    grant_type: "client_credentials" }.to_json )
	rescue => ex
		response = nil
	end
	if response.nil?
		puts "ERROR: no token"
	else
		token = response.parsed_response["access_token"].to_s
		headers = { 'Content-Type' => 'application/json',
					 'Authorization' => 'Bearer ' +  token }
	end
end

if config_raw.to_s.strip != ""
	meta_url = "http://localhost:3000/api/meta"
	response = HTTParty.post(meta_url,
					headers: headers,
					body: { "init": config_raw.to_s }.to_json)
end