module Simpro
	module CostCenter
		def self.sync_cost_center
     query = { 
         "columns"     => "ID,Name",
          "pageSize"      => 250,
          "page" => 1
       }
      cost_response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/setup/accounts/costCenters/?display=all",:query=> query, :headers => {
        "Content-Type" => "application/json",
         "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
      })
      cost_response.each_with_index do |cost_center_item,index|
        body_json = {
            "properties": {
              "simpro_id": cost_center_item["ID"],
              "name": cost_center_item["Name"]
            }
          }
      response = HTTParty.post("https://api.hubspot.com/crm/v3/objects/p_cost_centers",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
      end
       
    end

	end
end