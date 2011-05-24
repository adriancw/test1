require 'savon'
require 'json'
require 'yaml'

class EbayClient

  def initialize
    @client = Savon::Client.new do 
      wsdl.document = 'ebaySvc.wsdl.xml'
    end
    @endpoint = "https://api.sandbox.ebay.com/wsapi"
    @action   = "GeteBayOfficialTime"
    @version  = 405
    @ebayIds = begin
      YAML.load(File.open("ebayIds.yaml"))
    rescue Exception => e
      raise "Could not parse YAML: #{e.message}"
    end
  
    @endpoint_with_params = @endpoint + 
      "?callname=#{@action}&siteid=0&appid=#{@ebayIds["app_id"]}&version=#{@version}&routing=default"

    Savon.configure do |config|
      config.log = false            # disable logging
#      config.log_level = :error      # changing the log level
    end
    
  end
  
  # Encapsulate all access to instance variable access in this method to be called by @client.request()
  def soapRequestBlock(soapObj)
    soapObj.endpoint = @endpoint_with_params
    soapObj.header = {
      "urn:RequesterCredentials" => {
        "urn:eBayAuthToken" => @ebayIds["auth_token"],
        "urn:Credentials" => {
          "urn:AppId" => @ebayIds["app_id"], 
          "urn:DevId" => @ebayIds["dev_id"], 
          "urn:AuthCert" => @ebayIds["cert_id"]
        }
      }
    }
    soapObj.body = { "Version" => @version }
  end
  
  # make the request
  def getEbayTime
    xmlResp = @client.request :urn, "GeteBayOfficialTime" do |soap|
      # IMPORTANT: cannot use instance variables here, inside Savon::Client.request block
      # This is a closure that does not evaluate instance variables  see http://savonrb.com/#installation__resources
      # so we are putting the block into a method
      soapRequestBlock(soap)
    end   
    xmlResp.to_hash[:gete_bay_official_time_response]
  end

end


# Main client example
class TimeTest
  ec = EbayClient.new()
  respHash = ec.getEbayTime()
  respJson = respHash.to_json
  timestamp = respHash[:timestamp].to_s

  puts "Json response=" + respJson
  puts "Timestamp=" + timestamp
end
