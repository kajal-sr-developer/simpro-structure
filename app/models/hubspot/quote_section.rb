module Hubspot
	class QuoteSection

		SECTION_PATH='https://api.hubspot.com/crm/v3/objects/p_quote_sections'

		def self.create_quote_section(section)
			body_json = {
        "properties": {
           "section_id": section["ID"],
          "name": section["Name"]
        }
       }

       response = HTTParty.post("#{SECTION_PATH}/",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
		end



    def self.update_price(section_id,total,sub_total,tax)
      body_json = {
        "properties": {
          "section_total": total,
          "section_sub_total": sub_total,
          "section_gst": tax
        }
       }
        response = HTTParty.patch("#{SECTION_PATH}/#{section_id}/",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })

    end


		def self.get_quote_section(quote_section_id)
			 body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "section_id",
                "operator": "EQ",
                "value": "#{quote_section_id}"
              }
            ]
          }
        ]
      }
      response = HTTParty.post("#{SECTION_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
      return response
		end


		def self.get_quote_section_by_name(name)
			 body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "name",
                "operator": "EQ",
                "value": "#{name}"
              }
            ]
          }
        ]
      }
      response = HTTParty.post("#{SECTION_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
      return response
		end

		def self.associate_quote_section(deal_id,section_id)
			response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/deals/#{deal_id}/associations/p_quote_sections/#{section_id.to_i}/76?paginateAssociations=false",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
    end
	end
end