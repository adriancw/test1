require 'savon'
require 'json'
require 'yaml'

class EbayTime
	client = Savon::Client.new {
		wsdl.document = File.expand_path("~/dev/soap1/lib/ebaySvc.wsdl.xml", __FILE__)
	}

	endpoint = "https://api.sandbox.ebay.com/wsapi"
	action   = "GeteBayOfficialTime"
	version  = 405

	ebayIds = begin
		YAML.load(File.open("ebayIds.yaml"))
	rescue ArgumentError => e
		puts "Could not parse YAML: #{e.message}"
	end

	dev_id = ebayIds["dev_id"]
	app_id = ebayIds["app_id"]
	cert_id = ebayIds["cert_id"]
	auth_token = ebayIds["auth_token"]

	endpoint_with_params = endpoint +
		"?callname=#{action}&siteid=0&appid=#{app_id}&version=#{version}&routing=default"

	xmlResp = client.request :urn, "GeteBayOfficialTime" do
		soap.endpoint = endpoint_with_params
		soap.header = {
		  "urn:RequesterCredentials" => {
		    "urn:eBayAuthToken" => auth_token,
		    "urn:Credentials" => {
		      "urn:AppId" => app_id, "urn:DevId" => dev_id, "urn:AuthCert" => cert_id
		    }
		  }
		}
		soap.body = { "Version" => version }
	end
	puts '================================'
	
	respHash = xmlResp.to_hash[:gete_bay_official_time_response]
	puts "HashResult=" +  respHash.to_s
	puts "Timestamp=" + respHash[:timestamp].to_s
	respJson = respHash.to_json
	puts "JsonResult=" + respJson
end
