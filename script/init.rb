#!/usr/bin/env ruby
# encoding: utf-8

require 'httparty'
require 'linkeddata'
require 'rdf'

config_raw = ARGV.pop

init_url = "http://localhost:3000/api/init"
response = HTTParty.post(init_url)

if config_raw.to_s.strip != ""
	meta_url = "http://localhost:3000/api/meta"
	response = HTTParty.post(meta_url,
					headers: { 'Content-Type' => 'application/json' },
					body: { "init": config_raw.to_s }.to_json)
end