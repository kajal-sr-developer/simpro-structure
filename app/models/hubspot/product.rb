module Hubspot
	class Product
		PRODUCT_PATH = 'https://api.hubapi.com/crm/v3/objects/products'
                                                                                                                                                    
    def self.create(product,type)
        case  type
        when "Service"
          product_name = product["ServiceFee"]["Name"]
          sku = product["PartNo"] rescue product["ID"]
        when "Labour"
          product_name = product["LaborType"]["Name"]
          sku = product["PartNo"] rescue product["ID"]
        when "Catalog"
          product_name = product["Catalog"]["Name"]
          sku = product["Catalog"]["PartNo"] rescue product["ID"]
        when "Pre-Builds"
          product_name = product["Prebuild"]["Name"]
          sku = product["Prebuild"]["PartNo"] rescue product["ID"]
        else
          product_name = product["Name"]
          sku = product["PartNo"] rescue product["ID"]
        end
        if product["Type"] == "Material"
          product_name = product["Description"]
          sku = product["PartNo"] rescue product["ID"]
        end
        price = product["SellPrice"]["ExTax"] rescue 0
        if product_name.blank?
           product_name = product["Catalog"]["ID"].to_s rescue "N/A"
        end

        body_json = {
        "properties": {
          "name": product_name,
          "price": price,
          "hs_sku": sku,
          "part_no_": sku,
          "type": type 
        }
      }
        response = HTTParty.post("#{PRODUCT_PATH}",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json",
           "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
      return response
    end


    def self.create_product(product)
      uom = product["UOM"]["Name"] rescue ""
      group = product["Group"]["Name"] rescue ""
      part_no = product["PartNo"].present? ? product["PartNo"] : product["ID"]
       body_json = {
        "properties": {
          "name": product["Name"],
          "price":  product["SellPrice"],
          "hs_sku": part_no,
          "part_no_": product["PartNo"] ,
          "type": "Catalogue",
          "group": group,
        }
      }
        response = HTTParty.post("#{PRODUCT_PATH}",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json",
           "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })

        if response.success?
          puts "-----------#{product["Name"]}--------------------"
        end
    end





    def self.search_quoteline_item_product(product_name)
      sleep(2)
      amount = price rescue 0
      body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "name",
                "operator": "EQ",
                "value": "#{product_name}"
              }
            ],
          "limit": 1,
          }
        ]
      }
      response = HTTParty.post("#{PRODUCT_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
      if response["total"].present? && response["total"] > 1
        response["results"].each_with_index do |product,index|
          unless index == 0
             HTTParty.delete("#{PRODUCT_PATH}/#{product['id']}", :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
           
          end
        end
      end
      return response
    end
	end
end